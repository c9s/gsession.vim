" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
plugin/gsession.vim	[[[1
443
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

fun! s:defopt(n,v)
  if ! exists( a:n )
    let {a:n} = a:v
  endif
endf

fun! s:warn(msg)
  redraw
  echohl WarningMsg | echo a:msg | echohl None
endf


" *** SESSION UTIL FUNCTIONS

fun! s:session_dir()
  if exists('g:session_dir')
    let sesdir = expand( g:session_dir )
  elseif has('win32')
    let sesdir = expand('$VIMRUNTIME\session')
  else
    let sesdir = expand('$HOME/.vim/session')
  endif
  if !isdirectory(sesdir)
    cal mkdir(sesdir)
  endif
  return l:sesdir
endf

fun! s:session_filename()
  let filename = getcwd()

  " TODO: support hg
  let git_branch = system("git branch")
  if git_branch !~ 'Not a git repository' 
    let ref = system("git symbolic-ref HEAD")
    let filename = filename . '-git-' . ref
  endif
  return substitute( filename ,'[:\/]','-','g')
endf

fun! s:session_file()
  return s:session_dir() . s:sep . s:session_filename()
endf

fun! s:canonicalize_session_name(name)
  return substitute(a:name,'[^a-zA-Z0-9]','-','g')
endf

" list available sessions of current path
fun! s:get_cwd_sessionfiles()
  let out = glob( s:session_dir() . s:sep .'__'. s:session_filename() .'__*' )
  return split(out)
endf
" echo s:get_cwd_sessionfiles()
" sleep 1

" list all global sessions
fun! s:get_global_sessionfiles()
  let out = glob( s:session_dir() . s:sep . '__GLOBAL__*' )
  return split(out)
endf

fun! s:get_cwd_sessionnames()
  let items = s:get_cwd_sessionfiles()
  cal map(items," substitute(v:val,'^.*__.*__','','g')")
  return items
endf

fun! s:get_global_sessionnames()
  let items = s:get_global_sessionfiles()
  cal map(items," substitute(v:val,'.*__GLOBAL__','','g')")
  return items
endf



" Session name to path:
"
" return session path name:
" ~/.vim/session/__GLOBAL__[session name]
fun! s:namedsession_global_filepath(name)
  retu s:session_dir() . s:sep . '__GLOBAL__' . a:name
endf

" return session path name:
" ~/.vim/session/__[cwd]__[session name]
fun! s:namedsession_cwd_filepath(name)
  retu s:session_dir() . s:sep . '__' . s:session_filename() . '__' . a:name
endf





" Session name command-line completion functions
" ===============================================
fun! g:gsession_cwd_completion(arglead,cmdline,pos)
  let items = s:get_cwd_sessionnames()
  cal filter(items,"v:val =~ '^'.a:arglead")
  return items
endf

fun! g:gsession_global_completion(arglead,cmdline,pos)
  let items = s:get_global_sessionnames()
  cal filter(items,"v:val =~ '^'.a:arglead")
  return items
endf

fun! s:menu_load_local_session()
  let name = substitute( getline('.') , '^\s*' , '' , 'g' )
  let file = s:namedsession_cwd_filepath(name)
  if filereadable(file)
    wincmd q
    cal s:load_session(file)
  endif
endf

fun! s:list_local_sessions()
  10new
  let list = s:get_cwd_sessionnames()
  cal append( 0 , 'Local Sessions:' )
  cal map( list , '"   " . v:val' )
  cal append( 1 , list )
  setlocal buftype=nofile bufhidden=wipe nonu
  setlocal cursorline
  normal ggj
  nmap <buffer> <Enter> :cal <SID>menu_load_local_session()<CR>
endf
" cal s:list_local_sessions()


fun! s:read_session_files(name)

endf

fun! s:save_local_file_list(name)
  let script = []
  let bufend = bufnr('$')
  let buffers = [ ]
  for nr in range( 1 , bufend )
    if bufexists(nr)
      cal add(buffers,nr)
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
      cal add(script, "tabe " . bufname(nr) )
    else
      cal add(script, "badd " . bufname(nr) )
    endif

    " get window number
    " bufwinnr({expr})          *bufwinnr()*

  endfor
  let session_path = s:namedsession_cwd_filepath(a:name)
  cal writefile( script , session_path )
  echo script
  cal input('')
endf
" cal s:save_local_file_list('test')





fun! s:make_session(file)
  exec 'mksession! ' . a:file
  cal s:warn('Session [ ' . a:file . ' ] saved.' )
endf

fun! s:load_session(file)
  if filereadable(a:file)
    exec 'so ' . a:file
    cal s:warn('Session [ ' . a:file . ' ] loaded.' )
  else
    echoerr a:file . " not found."
  endif
endf




fun! s:gsession_make()
  let ses = v:this_session
  if strlen(ses) == 0
    let ses = s:session_file()
  endif
  cal s:make_session( ses )
endf

fun! s:auto_save_session()
  if exists('v:this_session') && v:this_session != ''
    cal s:make_session( v:this_session )
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
      cal s:load_session( ses )
      return
    elseif choice == 2
      redraw
      echo ""
      return
    elseif choice == 3
      redraw
      cal delete(ses)
      return
    endif
  endif
endf




fun! s:input_session_name(completer)
  let func = 'g:gsession_'. a:completer . '_completion'
  cal inputsave()
  let name = input("Session name: ", v:this_session ,'customlist,' . func )
  cal inputrestore()
  if strlen(name) > 0
    let name = s:canonicalize_session_name( name )
    return name
  endif
  echo "skipped."
  return ""
endf



fun! s:gsession_eliminate_all()
  let dir = s:session_dir()
  if isdirectory( dir ) > 0
    redraw
    cal s:warn( "Found " . dir . ". cleaning up..." )
    exec '!rm -rvf '. dir
    "XXX: delete command for windows.
    "XXX: use glob() and delete()
    cal s:warn( dir . " cleaned." )
  else
    cal s:warn( "Session dir [" . dir . "] not found" )
  endif
endf

fun! s:gsession_eliminate_current()
  if exists('v:this_session') && filereadable(v:this_session)
    cal delete( v:this_session )
    redraw
    cal s:warn( v:this_session . ' session deleted.' )
  else
    cal s:warn( 'Current session is not defined' )
  endif
endf





fun! s:make_namedsession_global()
  let sname = s:input_session_name('global')
  if strlen(sname) == 0
    retu
  endif
  let file = s:namedsession_global_filepath(sname)
  cal s:make_session(file)
endf

fun! s:make_namedsession_cwd()
  let sname = s:input_session_name('cwd')
  if strlen(sname) == 0
    retu
  endif
  let file = s:namedsession_cwd_filepath(sname)
  cal s:make_session(file)
endf

fun! s:load_namedsession_global()
  let sname = s:input_session_name('global')
  if strlen(sname) == 0
    retu
  endif
  let file = s:namedsession_global_filepath(sname)
  cal s:load_session( file )
endf

fun! s:load_namedsession_cwd()
  let sname = s:input_session_name('cwd')
  if strlen(sname) == 0
    retu
  endif
  let file = s:namedsession_cwd_filepath(sname)
  cal s:load_session( file )
endf

fun! s:make_local_session()
  if exists('g:local_session_filename')
    let local_filename = g:local_session_filename
  else
    let local_filename = 'Session.vim'
  endif
  cal s:make_session( local_filename )
endf


" default options
cal s:defopt('g:autoload_session',1)
cal s:defopt('g:autosave_session',1)

" =========== init
augroup GSession
  au!
augroup END

augroup GSession
  if g:autoload_session
    au VimEnter * nested cal s:auto_load_session()
  endif

  if g:autosave_session
    au VimLeave * cal s:auto_save_session()
  endif
augroup END

com! NamedSessionMakeCwd :cal s:make_namedsession_cwd()
com! NamedSessionMake    :cal s:make_namedsession_global()
com! NamedSessionLoadCwd :cal s:load_namedsession_cwd()
com! NamedSessionLoad    :cal s:load_namedsession_global()


com! GSessionMakeLocal          :cal s:make_local_session()
com! GSessionMake               :cal s:gsession_make()
com! GSessionEliminateAll       :cal s:gsession_eliminate_all()
com! GSessionEliminateCurrent   :cal s:gsession_eliminate_current()

com! GSessionListLocal :cal s:list_local_sessions()



" nmap: <leader>sl
"       is for making local session.

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
