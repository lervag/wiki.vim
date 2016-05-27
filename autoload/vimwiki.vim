" {{{1 Reload personal script
let s:file = expand('<sfile>')
if !exists('s:reloading_script')
  function! vimwiki#reload_personal_script()
    let s:reloading_script = 1
    execute 'source' s:file
    unlet s:reloading_script
  endfunction
endif

" }}}1

function! vimwiki#fix_syntax() " {{{1
  " Fix titles
  %s/^\(=\+\)\( .*\) \1$/\=repeat('#', len(submatch(1))) . submatch(2)/e

  " Remove leading '#' from journal references
  %s/^#\ze\[\[journal//e

  " Fix links [[...|...]] -> [...](...)
  %s/\[\[\%(\.\.\)\?\([^]|]*\)|\([^]]*\)\]\]/[\2](\1)/e

  " Fix code snippets
  %s/^{{{/```/e
  %s/^}}}/```/e
endfunction

" }}}1
function! vimwiki#backlinks() " {{{1
  let l:path = VimwikiGet('path')
  let l:file = fnamemodify(expand('%'),':r')
  let l:search = '"(\[[^]]*\]\(|\[\[)(.*\/)?' . l:file . '"'
  execute 'Ack ' . l:search l:path
endfunction

" }}}1
function! vimwiki#new_entry() " {{{
  let l:current = expand('%:t:r')

  " Get next weekday
  let l:candidate = systemlist('date -d "' . l:current . ' +1 day" +%F')[0]
  while systemlist('date -d "' . l:candidate . '" +%u')[0] > 5
    let l:candidate = systemlist('date -d "' . l:candidate . ' +1 day" +%F')[0]
  endwhile

  let l:next = expand('%:p:h') . '/' . l:candidate . '.wiki'
  if !filereadable(l:next)
    execute 'write' l:next
  endif

  VimwikiDiaryNextDay
endfunction

" }}}1
