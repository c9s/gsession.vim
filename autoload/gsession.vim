let s:save_cpo = &cpoptions
set cpoptions&vim


" Util Functions: {{{

" TODO: move plugin functions into autoload, thus don't need sid parsing.
function! gsession#set_plugin_sid_prefix(prefix)
  let s:plugin_sid_prefix = a:prefix
endfunction

function! gsession#plugin_sid_prefix()
  return s:plugin_sid_prefix
endfunction

" }}} Util Functions


let &cpoptions = s:save_cpo
unlet s:save_cpo


" modeline {{{
" vim: expandtab softtabstop=2 shiftwidth=2 foldmethod=marker
