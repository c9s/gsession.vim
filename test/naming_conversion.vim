" Last Modified: 2011-08-21
" Usage: with gsession loaded, :source this script.


" Util Functions: {{{

function! s:msg(msg)
  echomsg a:msg
endfunction

function! s:err(msg)
  echohl ErrorMsg | echomsg a:msg | echohl None
endfunction

function! s:test(msg, expr, ...)
  if a:0
    let l:expected = a:1
  endif
  let result = eval(a:expr)

  if exists('l:expected')
    if result == l:expected
      call s:msg(a:msg . "  " . result . "    " . '(PASSED)')
    else
      call s:err(a:msg . "  " . result . "    " . '(FAILED)')
    endif
  else
    call s:msg(a:msg . "  " . result)
  endif
endfunction

function! s:msg_begin()
  call s:msg(repeat('=', 78))
  call s:msg("Naming Conversion Testing, target path: ")
  call s:msg('  ' . s:target_path)
  call s:msg(repeat('-', 78))
endfunction

function! s:msg_end()
  call s:msg(' ')
endfunction

function! s:prefixed(expr)
  return s:SID_PREFIX . a:expr
endfunction

" }}} Util Functions


let s:SID_PREFIX = gsession#plugin_sid_prefix()


" Session without names (without branch): {{{
let s:target_path = '/dir/.vim/session/-some.path'

call s:msg_begin()
call s:test("session_dir: ", s:prefixed('session_dir(s:target_path)'), '/dir/.vim/session')
call s:test("session_identity: ", s:prefixed('session_identity(s:target_path)'), '-some.path')
call s:test("session_location: ", s:prefixed('session_location(s:target_path)'), '-some.path')
call s:test("session_branch: ", s:prefixed('session_branch(s:target_path)'), '')
call s:test("session_name: ", s:prefixed('session_name(s:target_path)'), '')
call s:msg_end()
" }}}

" Session without names (with branch): {{{
let s:target_path = '/dir/.vim/session/-some.path-git--Branch名稱foo__bar'

call s:msg_begin()
call s:test("session_dir: ", s:prefixed('session_dir(s:target_path)'), '/dir/.vim/session')
call s:test("session_identity: ", s:prefixed('session_identity(s:target_path)'), '-some.path-git--Branch名稱foo__bar')
call s:test("session_location: ", s:prefixed('session_location(s:target_path)'), '-some.path')
call s:test("session_branch: ", s:prefixed('session_branch(s:target_path)'), '-git--Branch名稱foo__bar')
call s:test("session_name: ", s:prefixed('session_name(s:target_path)'), '')
call s:msg_end()
" }}}

" Local sessions: {{{
let s:target_path = '/dir/.vim/session/__-some.path-git--Branch名稱foo__bar__foo-bar'

call s:msg_begin()
call s:test("session_dir: ", s:prefixed('session_dir(s:target_path)'), '/dir/.vim/session')
call s:test("session_identity: ", s:prefixed('session_identity(s:target_path)'), '-some.path-git--Branch名稱foo__bar')
call s:test("session_location: ", s:prefixed('session_location(s:target_path)'), '-some.path')
call s:test("session_branch: ", s:prefixed('session_branch(s:target_path)'), '-git--Branch名稱foo__bar')
call s:test("session_name: ", s:prefixed('session_name(s:target_path)'), 'foo-bar')
call s:msg_end()
" }}}

" Global session: {{{
let s:target_path = '/dir/.vim/session/__GLOBAL__foo-bar'

call s:msg_begin()
call s:test("session_dir: ", s:prefixed('session_dir(s:target_path)'), '/dir/.vim/session')
call s:test("session_identity: ", s:prefixed('session_identity(s:target_path)'), '')
call s:test("session_location: ", s:prefixed('session_location(s:target_path)'), '')
call s:test("session_branch: ", s:prefixed('session_branch(s:target_path)'), '')
call s:test("session_name: ", s:prefixed('session_name(s:target_path)'), 'foo-bar')
call s:msg_end()
" }}}

" Auto detection (no arguments): {{{
let s:target_path = 'NO (check the results yourself!)'

call s:msg_begin()
call s:test("session_dir: ", s:prefixed('session_dir()'))
call s:test("session_identity: ", s:prefixed('session_identity()'))
call s:test("session_location: ", s:prefixed('session_location()'))
call s:test("session_branch: ", s:prefixed('session_branch()'))
call s:test("session_name: ", s:prefixed('session_name()'))
call s:test("session_file: ", s:prefixed('session_file()'))
call s:msg_end()
" }}}


" modeline {{{
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
