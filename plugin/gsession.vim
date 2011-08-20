" Global Session ============================================
" Author: Cornelius
" Mail:   cornelius.howl@gmail.com
" Web:    http://oulixe.us
" Version: 0.23
" Description:
"
"   global session is:   you can open the session file set everywhere.
"
"   local session is:    located by current directory.
"                        for example, you change to ~/dir directory
"                        every local session that was made from the path, will
"                        only be listed when you are in ~/dir directory.
"
"   naming rule:
"       's' + lower case  are for local sessions
"       's' + upper case  are for global sessions
"
" Options:
"     g:session_dir                   [String]
"     g:local_session_filename        [String]
"     g:autoload_session              [Number]
"     g:autosave_session              [Number]
"     g:gsession_non_default_mapping  [Number]
"
" Usage:
"
"     <leader>ss    create global session file (located in ~/.vim/session by
"                   default)
"
"     <leader>sS    create local session file
"
"
"     <leader>se    eliminate current session file (including local session
"                   file or global session file)
"
"     <leader>sE    eliminate all session file (eliminate global session only).

" set sessionoptions-=curdir
" set sessionoptions+=sesdir
" set sessionoptions-=buffers


" *** PREPROCESS

if has('win32')
  let s:sep = '\'
else
  let s:sep = '/'
endif


" *** UTIL FUNCTIONS

function! s:defopt(n, v)
  if ! exists(a:n)
    let {a:n} = a:v
  endif
endfunction

function! s:warn(msg)
  redraw
  echohl WarningMsg | echo a:msg | echohl None
endfunction


" *** SESSION UTIL FUNCTIONS

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

function! s:session_filename()
  let filename = getcwd()

  " TODO: support hg
  if filereadable('.git' . s:sep . 'HEAD')
    let head = readfile('.git' . s:sep . 'HEAD')
    let len = strlen('ref: refs/heads/')
    let filename = filename . '-git-' . strpart(head[0], len-1)
  endif
  return substitute(filename ,'[:\/]','-','g')
endfunction

function! s:session_file()
  return s:session_dir() . s:sep . s:session_filename()
endfunction

function! s:canonicalize_session_name(name)
  return substitute(a:name,'[^a-zA-Z0-9]','-','g')
endfunction

" list available sessions of current path
function! s:get_cwd_sessionfiles()
  let out = glob(s:session_dir() . s:sep .'__'. s:session_filename() .'__*')
  return split(out)
endfunction
" echo s:get_cwd_sessionfiles()
" sleep 1

" list all global sessions
function! s:get_global_sessionfiles()
  let out = glob(s:session_dir() . s:sep . '__GLOBAL__*')
  return split(out)
endfunction

function! s:get_cwd_sessionnames()
  let items = s:get_cwd_sessionfiles()
  call map(items," substitute(v:val,'^.*__.*__','','g')")
  return items
endfunction

function! s:get_global_sessionnames()
  let items = s:get_global_sessionfiles()
  call map(items," substitute(v:val,'.*__GLOBAL__','','g')")
  return items
endfunction



" Session name to path:
"
" return session path name:
" ~/.vim/session/__GLOBAL__[session name]
function! s:namedsession_global_filepath(name)
  return s:session_dir() . s:sep . '__GLOBAL__' . a:name
endfunction

" return session path name:
" ~/.vim/session/__[cwd]__[session name]
function! s:namedsession_cwd_filepath(name)
  return s:session_dir() . s:sep . '__' . s:session_filename() . '__' . a:name
endfunction





" Session name command-line completion functions
" ===============================================
function! g:gsession_cwd_completion(arglead,cmdline,pos)
  let items = s:get_cwd_sessionnames()
  call filter(items,"v:val =~ '^'.a:arglead")
  return items
endfunction

function! g:gsession_global_completion(arglead,cmdline,pos)
  let items = s:get_global_sessionnames()
  call filter(items,"v:val =~ '^'.a:arglead")
  return items
endfunction

function! s:menu_load_local_session()
  let name = substitute(getline('.') , '^\s*' , '' , 'g')
  let file = s:namedsession_cwd_filepath(name)
  if filereadable(file)
    wincmd q
    call s:load_session(file)
  endif
endfunction

function! s:list_local_sessions()
  10new
  let list = s:get_cwd_sessionnames()
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
      call add(buffers,nr)
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
  let session_path = s:namedsession_cwd_filepath(a:name)
  call writefile(script , session_path)
  echo script
  call input('')
endfunction
" call s:save_local_file_list('test')





function! s:make_session(file)
  execute 'mksession! ' . a:file
  call s:warn('Session [ ' . a:file . ' ] saved.')
endfunction

function! s:load_session(file)
  if filereadable(a:file)
    execute 'so ' . a:file
    call s:warn('Session [ ' . a:file . ' ] loaded.')
    return 1
  endif
  return 0
endfunction


function! s:gsession_make()
  let ses = v:this_session
  if strlen(ses) == 0
    let ses = s:session_file()
  endif
  call s:make_session(ses)
endfunction

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
      call s:load_session(ses)
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




function! s:input_session_name(completer)
  let func = 'g:gsession_'. a:completer . '_completion'
  call inputsave()
  let name = input("Session name: ", v:this_session ,'customlist,' . func)
  call inputrestore()
  if strlen(name) > 0
    let name = s:canonicalize_session_name(name)
    return name
  endif
  echo "skipped."
  return ""
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





function! s:make_namedsession_global()
  let sname = s:input_session_name('global')
  if strlen(sname) == 0
    return
  endif
  let file = s:namedsession_global_filepath(sname)
  call s:make_session(file)
endfunction

function! s:make_namedsession_cwd()
  let sname = s:input_session_name('cwd')
  if strlen(sname) == 0
    return
  endif
  let file = s:namedsession_cwd_filepath(sname)
  call s:make_session(file)
endfunction

function! s:load_namedsession_global()
  let sname = s:input_session_name('global')
  if strlen(sname) == 0
    return
  endif
  let file = s:namedsession_global_filepath(sname)
  call s:load_session(file)
endfunction

function! s:load_namedsession_cwd()
  let sname = s:input_session_name('cwd')
  if strlen(sname) == 0
    return
  endif
  let file = s:namedsession_cwd_filepath(sname)
  call s:load_session(file)
endfunction

function! s:make_local_session()
  if exists('g:local_session_filename')
    let local_filename = g:local_session_filename
  else
    let local_filename = 'Session.vim'
  endif
  call s:make_session(local_filename)
endfunction


" default options
call s:defopt('g:autoload_session',1)
call s:defopt('g:autosave_session',1)

" =========== init
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

command! NamedSessionMakeCwd :call s:make_namedsession_cwd()
command! NamedSessionMake    :call s:make_namedsession_global()
command! NamedSessionLoadCwd :call s:load_namedsession_cwd()
command! NamedSessionLoad    :call s:load_namedsession_global()


command! GSessionMakeLocall          :call s:make_local_session()
command! GSessionMake               :call s:gsession_make()
command! GSessionEliminateAll       :call s:gsession_eliminate_all()
command! GSessionEliminateCurrent   :call s:gsession_eliminate_current()

command! GSessionListLocall :call s:list_local_sessions()



" nmap: <leader>sl
"       is for making locall session.

if exists('g:gsession_non_default_mapping')
  finish
endif


nnoremap <leader>ss    :GSessionMakeLocal<CR>
nnoremap <leader>sS    :GSessionMake<CR>

nnoremap <leader>sn    :NamedSessionMakeCwd<CR>
nnoremap <leader>sN    :NamedSessionMake<CR>

nnoremap <leader>sl    :NamedSessionLoadCwd<CR>
nnoremap <leader>sL    :NamedSessionLoad<CR>

nnoremap <leader>se    :GSessionEliminateCurrent<CR>
nnoremap <leader>sE    :GSessionEliminateAll<CR>


nnoremap <leader>sm    :GSessionListLocal<CR>
