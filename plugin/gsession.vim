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
"     <leader>sl    create local session file
"
"     <leader>ss    create global session file (located in ~/.vim/session by
"                   default)
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
  exec ':mksession! ' . ses
  cal s:warn( "Session saved: " . ses )
endf

fun! s:auto_save_session()
  if exists(v:this_session)
    exe "mks! " . v:this_session
    cal s:warn( "Session saved: " . v:this_session )
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

fun! s:make_local_session()
  if exists('g:local_session_filename')
    let local_filename = g:local_session_filename
  else
    let local_filename = 'Session.vim'
  endif
  exec 'mksession! ' . local_filename
  cal s:warn('Local session [' . local_filename . '] created.' )
endf

augroup AutoLoadSession
  au!
  au VimEnter * cal s:auto_load_session()
  au VimLeave * cal s:auto_save_session()
augroup END

com! GlobalSessionMakeLocal          :cal s:make_local_session()
com! GlobalSessionMake               :cal s:gsession_make()
com! GlobalSessionEliminateAll       :cal s:gsession_eliminate_all()
com! GlobalSessionEliminateCurrent   :cal s:gsession_eliminate_current()

" nmap: <leader>sl  
"       is for making local session.
nnoremap <leader>sl    :mksession!<CR>
nnoremap <leader>ss    :GlobalSessionMake<CR>
nnoremap <leader>se    :GlobalSessionEliminateCurrent<CR>
nnoremap <leader>sE    :GlobalSessionEliminateAll<CR>

