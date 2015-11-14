" Global Session ============================================
" Author: Cornelius
" Mail:   cornelius.howl@gmail.com
" Web:    http://oulixe.us
" Version: 0.23

if exists('g:loaded_gsession')
  finish
endif
let g:loaded_gsession = 1
let s:save_cpo = &cpoptions
set cpoptions&vim


" Naming Conversion: {{{
"
" Session file names:
"
"   1. Session without names:
"     {session_location}{session_branch}
"
"   2. Local sessions:
"     __{session_location}{session_branch}__{session_name}
"
"   3. Global session:
"     __GLOBAL__{session_name}
"
"   Example full session_file path:
"     /dir/.vim/session/__-some-dir-some.path-git--refactoring__foo-bar-foobar
"     {  session_dir   }  {session_location }{session_branch }  {session_name}
"                         {       i.e. session_identity      }

fun! s:session_dir(...)
  if a:0 > 0 && strlen(a:1)
    return fnamemodify(a:1, ':p:h')
  endif

  if exists('g:session_dir')
    let sesdir = expand(g:session_dir)
  elseif has('win32') || has('win64')
    let sesdir = expand('$HOME\vimfiles\session')
  else
    let sesdir = expand('$HOME/.vim/session')
  endif
  if !isdirectory(sesdir)
    call mkdir(sesdir, 'p')
  endif
  return l:sesdir
endf

fun! s:session_identity(...)
  if a:0 > 0 && strlen(a:1)
    let tail = fnamemodify(a:1, ':t')
    if match(tail, '^__GLOBAL__') >= 0
      return ''
    elseif match(tail, '^__') >= 0
      return strpart(
            \   tail,
            \   2,
            \   strlen(tail) - 2 - strlen(split(tail, '\ze__')[-1])
            \ )
    else
      return tail
    endif
  endif

  return substitute(
        \   s:session_location() . s:session_branch(),
        \   '[:\/]',
        \   '-',
        \   'g'
        \ )
endf

fun! s:session_location(...)
  if a:0 > 0 && strlen(a:1)
    return substitute(s:session_identity(a:1), s:session_branch(a:1), '', '')
  endif
  return getcwd()
endf

fun! s:session_branch(...)
  " TODO: support hg

  if a:0 > 0 && strlen(a:1)
    return matchstr(s:session_identity(a:1), '-git--.*$', '', '')
  endif

  let branch = system("git symbolic-ref --short HEAD")

  return v:shell_error ?
        \ '' :
        \ printf('-git--%s', substitute(branch, '\n$', '', ''))
endf

fun! s:session_name(...)
  if a:0 > 0 && strlen(a:1)
    let tail = fnamemodify(a:1, ':t')
    if match(tail, '^__') >= 0
      return split(tail, '__')[-1]
    endif
  endif
  return ''
endf

fun! s:session_file()
  return s:session_dir() . s:sep . s:session_identity()
endf

fun! s:session_file_with_name(name, global)
  if a:global
    return s:session_dir() . s:sep . '__GLOBAL__' . a:name
  else
    return s:session_dir() . s:sep . '__' . s:session_identity() . '__' . a:name
  endif
endf

fun! s:canonicalize_session_name(name)
  return substitute(a:name, '[^a-zA-Z0-9]', '-', 'g')
endf

" }}} Naming Conversion


" Util Functions: {{{

fun! s:defopt(n, v)
  if ! exists(a:n)
    let {a:n} = a:v
  endif
endf

fun! s:warn(msg)
  redraw
  echohl WarningMsg | echo a:msg | echohl None
endf

" TODO: don't pollute "g:" scope.
fun! g:Complete_names(arglead, cmdline, pos)
  let items = s:session_names(s:completing_global)
  return filter(items, "v:val =~ '^' . a:arglead")
endf

fun! s:input_session_name(global)
  let s:completing_global = a:global
  call inputsave()
  let name = input(
        \   "Session name: ",
        \   strlen('v:this_session') ? s:session_name(v:this_session) : '',
        \   'customlist,g:Complete_names'
        \ )
  call inputrestore()

  if strlen(name) > 0
    return s:canonicalize_session_name(name)
  endif

  echo "skipped."
endf

fun! s:session_files(global)
  if a:global
    let pattern = '__GLOBAL__'
  else
    let pattern = '__' . s:session_identity() . '__'
  endif

  return split(glob(s:session_dir() . s:sep . pattern . '*', ''))
endf

fun! s:session_names(global)
  if a:global
    let pattern = '^.*__GLOBAL__'
  else
    let pattern = '^.*__.*__'
  endif

  return map(
        \   s:session_files(a:global),
        \   "substitute(v:val, '" . pattern . "', '', 'g')"
        \ )
endf

fun! s:SID_PREFIX()
  return matchstr(expand('<sfile>'), '<SNR>\d\+_')
endf

" }}} Util Functions


" Session Operations: {{{

fun! s:make_session(file)
  execute 'mksession! ' . a:file
  call s:warn('Session [ ' . a:file . ' ] saved.')
endf

fun! s:load(file)
  if filereadable(a:file)
    execute 'source ' . a:file
    call s:warn('Session [ ' . a:file . ' ] loaded.')
    return 1
  endif
  return 0
endf

fun! s:save(global)
  if a:global
    let file = strlen(v:this_session) ? v:this_session : s:session_file()
  else
    let file = exists('g:local_session_filename') ? g:local_session_filename : "Session.vim"
  endif

  call s:make_session(file)
endf

fun! s:save_with_name(name, global)
  " TODO: with a:name provided, use it.
  let name = s:input_session_name(a:global)
  if strlen(name) == 0
    return
  endif
  let file = s:session_file_with_name(name, a:global)
  call s:make_session(file)
endf

fun! s:load_with_name(name, global)
  " TODO: with a:name provided, use it.
  let name = s:input_session_name(a:global)
  if strlen(name) == 0
    return
  endif
  let file = s:session_file_with_name(name, a:global)
  call s:load(file)
endf

" }}} Session Operations


" Main Functions: {{{

fun! s:auto_save_session()
  if exists('v:this_session') && v:this_session != ''
    call s:make_session(v:this_session)
  endif
endf

fun! s:auto_load_session()
  if argc() > 0
    return
  endif

  if exists('g:local_session_filename')
    let local_filename = g:local_session_filename
  else
    let local_filename = 'Session.vim'
  endif

  let local_ses = getcwd() . s:sep . local_filename

  if filereadable(local_ses)
    let ses = local_ses
  else
    let ses = s:session_file()
  endif

  if filereadable(ses)
    let choice = confirm("Session file exists.", "&Load\n&Ignore\n&Delete", 0)
    if choice == 1
      call s:load(ses)
      return
    elseif choice == 2
      redraw
      echo ""
      return
    elseif choice == 3
      redraw
      call delete(ses)
      return
    endif
  endif
endf

fun! s:gsession_eliminate_all()
  let dir = s:session_dir()
  if isdirectory(dir) > 0
    redraw
    call s:warn("Found " . dir . ". cleaning up...")
    execute '!rm -rvf '. dir
    "XXX: delete command for windows.
    "XXX: use glob() and delete()
    call s:warn(dir . " cleaned.")
  else
    call s:warn("Session dir [" . dir . "] not found")
  endif
endf

fun! s:gsession_eliminate_current()
  if exists('v:this_session') && filereadable(v:this_session)
    call delete(v:this_session)
    redraw
    call s:warn(v:this_session . ' session deleted.')
  else
    call s:warn('Current session is not defined')
  endif
endf

" }}} Main Functions


" Experimental: {{{

fun! s:menu_load_local_session()
  let name = substitute(getline('.') , '^\s*' , '' , 'g')
  let file = s:session_file_with_name(name, 0)
  if filereadable(file)
    wincmd q
    call s:load(file)
  endif
endf

fun! s:list_local_sessions()
  10new
  let list = s:session_names(0)
  call append(0 , 'Locall Sessions:')
  call map(list , '"   " . v:val')
  call append(1 , list)
  setlocal buftype=nofile bufhidden=wipe nonumber
  setlocal cursorline
  normal ggj
  nmap <buffer> <Enter> :call <SID>menu_load_local_session()<CR>
endf
" call s:list_local_sessions()

fun! s:read_session_files(name)

endf

fun! s:save_local_file_list(name)
  let script = []
  let bufend = bufnr('$')
  let buffers = [ ]
  for nr in range(1 , bufend)
    if bufexists(nr)
      call add(buffers, nr)
    endif
  endfor
  for nr in buffers
    let file = bufname(nr)
    if ! filereadable(file)
      continue
    endif
    if ! buflisted(nr)
      continue
    endif

    if bufloaded(nr)
      call add(script, "tabe " . bufname(nr))
    else
      call add(script, "badd " . bufname(nr))
    endif

    " get window number
    " bufwinnr({expr})          *bufwinnr()*

  endfor
  let session_path = s:session_file_with_name(a:name, 0)
  call writefile(script , session_path)
  echo script
  call input('')
endf
" call s:save_local_file_list('test')

" }}} Experimental


let s:sep = has('win32') ? '\' : '/'

call s:defopt('g:autoload_session', 1)
call s:defopt('g:autosave_session', 1)
call gsession#set_plugin_sid_prefix(s:SID_PREFIX())

augroup GSession
  au!
  if g:autoload_session
    autocmd VimEnter * nested call s:auto_load_session()
  endif

  if g:autosave_session
    autocmd VimLeave * call s:auto_save_session()
  endif
augroup END

command! NamedSessionMakeCwd :call s:save_with_name('', 0)
command! NamedSessionMake    :call s:save_with_name('', 1)
command! NamedSessionLoadCwd :call s:load_with_name('', 0)
command! NamedSessionLoad    :call s:load_with_name('', 1)

command! GSessionMakeLocall         :call s:save(0)
command! GSessionMake               :call s:save(1)
command! GSessionEliminateAll       :call s:gsession_eliminate_all()
command! GSessionEliminateCurrent   :call s:gsession_eliminate_current()

command! GSessionListLocall :call s:list_local_sessions()

if ! exists('g:gsession_non_default_mapping')
  nnoremap <leader>ss    :GSessionMakeLocal<CR>
  nnoremap <leader>sS    :GSessionMake<CR>

  nnoremap <leader>sn    :NamedSessionMakeCwd<CR>
  nnoremap <leader>sN    :NamedSessionMake<CR>

  nnoremap <leader>sl    :NamedSessionLoadCwd<CR>
  nnoremap <leader>sL    :NamedSessionLoad<CR>

  nnoremap <leader>se    :GSessionEliminateCurrent<CR>
  nnoremap <leader>sE    :GSessionEliminateAll<CR>

  nnoremap <leader>sm    :GSessionListLocal<CR>
endif


let &cpoptions = s:save_cpo
unlet s:save_cpo


" modeline {{{
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
