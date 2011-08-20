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

function! s:session_dir()
  if exists('g:session_dir')
    let sesdir = expand(g:session_dir)
  elseif has('win32')
    let sesdir = expand('$VIMRUNTIME\session')
  else
    let sesdir = expand('$HOME/.vim/session')
  endif
  if !isdirectory(sesdir)
    call mkdir(sesdir)
  endif
  return l:sesdir
endfunction

function! s:session_identity()
  return substitute(
        \   s:session_location() . s:session_branch(),
        \   '[:\/]',
        \   '-',
        \   'g'
        \ )
endfunction

function! s:session_location()
  return getcwd()
endfunction

function! s:session_branch()
  " TODO: support hg
  if filereadable('.git' . s:sep . 'HEAD')
    let head = readfile('.git' . s:sep . 'HEAD')
    let len = strlen('ref: refs/heads/')
    return '-git-' . strpart(head[0], len - 1)
  else
    return ''
  endif
endfunction

function! s:session_name()
  return matchstr(s:session_identity(), '.*__\zs[a-zA-Z0-9-]\+$')
endfunction

function! s:session_file()
  return s:session_dir() . s:sep . s:session_identity()
endfunction

function! s:session_file_with_name(name, global)
  if a:global
    return s:session_dir() . s:sep . '__GLOBAL__' . a:name
  else
    return s:session_dir() . s:sep . '__' . s:session_identity() . '__' . a:name
  endif
endfunction

function! s:canonicalize_session_name(name)
  return substitute(a:name, '[^a-zA-Z0-9]', '-', 'g')
endfunction

" }}} Naming Conversion


" Util Functions: {{{

function! s:defopt(n, v)
  if ! exists(a:n)
    let {a:n} = a:v
  endif
endfunction

function! s:warn(msg)
  redraw
  echohl WarningMsg | echo a:msg | echohl None
endfunction

" TODO: don't pollute "g:" scope.
function! g:complete_names(arglead, cmdline, pos)
  let items = s:session_names(s:completing_global)
  return filter(items, "v:val =~ '^' . a:arglead")
endfunction

function! s:input_session_name(global)
  let s:completing_global = a:global
  call inputsave()
  let name = input("Session name: ", s:session_name(), 'customlist,g:complete_names')
  call inputrestore()

  if strlen(name) > 0
    return s:canonicalize_session_name(name)
  endif

  echo "skipped."
endfunction

function! s:session_files(global)
  if a:global
    let pattern = '__GLOBAL__'
  else
    let pattern = '__' . s:session_identity() . '__'
  endif

  return split(glob(s:session_dir() . s:sep . pattern . '*', ''))
endfunction

function! s:session_names(global)
  if a:global
    let pattern = '^.*__GLOBAL__'
  else
    let pattern = '^.*__.*__'
  endif

  return map(
        \   s:session_files(a:global),
        \   "substitute(v:val, '" . pattern . "', '', 'g')"
        \ )
endfunction


" }}} Util Functions


" Session Operations: {{{

function! s:make_session(file)
  execute 'mksession! ' . a:file
  call s:warn('Session [ ' . a:file . ' ] saved.')
endfunction

function! s:load(file)
  if filereadable(a:file)
    execute 'source ' . a:file
    call s:warn('Session [ ' . a:file . ' ] loaded.')
    return 1
  endif
  return 0
endfunction

function! s:save(global)
  if a:global
    let file = strlen(v:this_session) ? v:this_session : s:session_file()
  else
    let file = exists('g:local_session_filename') ? g:local_session_filename : "Session.vim"
  endif

  call s:make_session(file)
endfunction

function! s:save_with_name(name, global)
  " TODO: with a:name provided, use it.
  let name = s:input_session_name(a:global)
  if strlen(name) == 0
    return
  endif
  let file = s:session_file_with_name(name, a:global)
  call s:make_session(file)
endfunction

function! s:load_with_name(name, global)
  " TODO: with a:name provided, use it.
  let name = s:input_session_name(a:global)
  if strlen(name) == 0
    return
  endif
  let file = s:session_file_with_name(name, a:global)
  call s:load(file)
endfunction

" }}} Session Operations


" Main Functions: {{{

function! s:auto_save_session()
  if exists('v:this_session') && v:this_session != ''
    call s:make_session(v:this_session)
  endif
endfunction

function! s:auto_load_session()
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
endfunction

function! s:gsession_eliminate_all()
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
endfunction

function! s:gsession_eliminate_current()
  if exists('v:this_session') && filereadable(v:this_session)
    call delete(v:this_session)
    redraw
    call s:warn(v:this_session . ' session deleted.')
  else
    call s:warn('Current session is not defined')
  endif
endfunction

" }}} Main Functions


" Experimental: {{{

function! s:menu_load_local_session()
  let name = substitute(getline('.') , '^\s*' , '' , 'g')
  let file = s:session_file_with_name(name, 0)
  if filereadable(file)
    wincmd q
    call s:load(file)
  endif
endfunction

function! s:list_local_sessions()
  10new
  let list = s:session_names(0)
  call append(0 , 'Locall Sessions:')
  call map(list , '"   " . v:val')
  call append(1 , list)
  setlocall buftype=nofile bufhidden=wipe nonumber
  setlocall cursorline
  normal ggj
  nmap <buffer> <Enter> :call <SID>menu_load_local_session()<CR>
endfunction
" call s:list_local_sessions()

function! s:read_session_files(name)

endfunction

function! s:save_local_file_list(name)
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
endfunction
" call s:save_local_file_list('test')

" }}} Experimental


let s:sep = has('win32') ? '\' : '/'

call s:defopt('g:autoload_session', 1)
call s:defopt('g:autosave_session', 1)

augroup GSession
  autocmd!
augroup END

augroup GSession
  if g:autoload_session
    autocmd VimEnter * nested call s:auto_load_session()
  endif

  if g:autosave_session
    augroup VimLeave * call s:auto_save_session()
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
