" Global Session ============================================
" Author: Cornelius
" Mail:   cornelius.howl@gmail.com
" Web:    http://oulixe.us
"
" Options:
"     g:local_session_filename [String]
"     g:session_dir            [String]
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

set sessionoptions-=curdir
set sessionoptions+=sesdir

fun! s:warn(msg)
  redraw
  echohl WarningMsg | echo a:msg | echohl None
endf

fun! s:make_session(file)
  exec 'mksession! ' . a:file
  cal s:warn('Session [ ' . a:file . ' ] saved.' )
endf

fun! s:load_session(file)
  exec 'so! ' . a:file
  cal s:warn('Session [ ' . a:file . ' ] loaded.' )
endf

fun! s:session_dir()
  if exists('g:session_dir')
    let sesdir = expand( g:session_dir )
  else
    let sesdir = expand('~/.vim/session')
  endif
  if !isdirectory(sesdir) 
    cal mkdir(sesdir)
  endif
  return l:sesdir
endf

fun! s:session_filename()
  let filename = substitute(getcwd(),'[/]','-','g')
  return filename
endf

fun! s:session_file()
  return s:session_dir().  '/' . s:session_filename()
endf

fun! s:gsession_make()
  let ses = v:this_session
  if strlen(ses) == 0
    let ses = s:session_file()
  endif
  cal s:make_session( ses )
endf

fun! s:auto_save_session()
  if exists(v:this_session)
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

  let local_ses = getcwd() . '/' . local_filename
  if filereadable(local_ses)
    let ses = local_ses
  else
    let ses = s:session_file()
  endif
  if filereadable(ses)
    cal s:warn( "Session file exists. Load this? (y/n): " )
    while 1
      let c = getchar()
      if c == char2nr("y")
        exec 'so ' . ses
        cal s:warn( ses . ' session loaded.' )
        return
      elseif c == char2nr("n")
        redraw
        echo ""
        return
      endif
    endwhile
  endif
endf


fun! s:gsession_eliminate_all()
  let dir = s:session_dir()
  if isdirectory( dir ) > 0 
    redraw
    cal s:warn( "Found " . dir . ". cleaning up..." )
    exec '!rm -rvf '. dir
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


" list available session of current path
fun! s:namedsession_list_cwd()

endf

fun! s:namedsession_list_global()

endf

fun! g:gsession_completion(arglead,cmdline,pos)
  let out = glob( s:session_dir() . '/__GLOBAL__*' )
  let items = split(out)
  cal map(items," substitute(v:val,'.*__GLOBAL__','','g')")
  cal filter(items,"v:val =~ '^'.a:arglead")
  return items
endf

fun! s:canonicalize_session_name(name)
  return substitute(a:name,'[^a-zA-Z0-9]','-','g')
endf

fun! s:input_session_name()
  cal inputsave()
  let name = input("Session name:",'','customlist,g:gsession_completion')
  cal inputrestore()
  if strlen(name) > 0
    let name = s:canonicalize_session_name( name )
    return name
  endif
  return ""
endf

" ~/.vim/session/[cwd]__[session name]
fun! s:make_namedsession_cwd()

endf

fun! s:global_namedsession_filepath(name)
  retu s:session_dir() . '/__GLOBAL__' . a:name
endf

" ~/.vim/session/__GLOBAL__[session name]
fun! s:make_namedsession_global()
  let sname = s:input_session_name()
  if strlen(sname) == 0
    retu
  endif
  let file = s:global_namedsession_filepath(sname)
  cal s:make_session(file)
endf


fun! s:load_namedsession_global()
  let sname = s:input_session_name()
  if strlen(sname) == 0
    retu
  endif
  let file = s:global_namedsession_filepath(sname)
  exec 'so! ' . file
endf

fun! s:make_local_session()
  if exists('g:local_session_filename')
    let local_filename = g:local_session_filename
  else
    let local_filename = 'Session.vim'
  endif
  cal s:make_session( local_filename )
endf

augroup AutoLoadSession
  au!
  au VimEnter * cal s:auto_load_session()
  au VimLeave * cal s:auto_save_session()
augroup END


com! GlobalSessionMakeNameCwd :cal s:make_namedsession_cwd()
com! GlobalSessionMakeName    :cal s:make_namedsession_global()

com! GlobalSessionMakeLocal          :cal s:make_local_session()
com! GlobalSessionMake               :cal s:gsession_make()
com! GlobalSessionEliminateAll       :cal s:gsession_eliminate_all()
com! GlobalSessionEliminateCurrent   :cal s:gsession_eliminate_current()

" nmap: <leader>sl  
"       is for making local session.
nnoremap <leader>sS    :GlobalSessionMakeLocal<CR>
nnoremap <leader>ss    :GlobalSessionMake<CR>
nnoremap <leader>se    :GlobalSessionEliminateCurrent<CR>
nnoremap <leader>sE    :GlobalSessionEliminateAll<CR>

