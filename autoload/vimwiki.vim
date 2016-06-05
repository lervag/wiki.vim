" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

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

  call vimwiki#diary#goto_next_day()
endfunction

" }}}1

" {{{1 function! vimwiki#reload()
let s:file = expand('<sfile>')
if !exists('s:reloading_script')
  function! vimwiki#reload()
    let s:reloading_script = 1

    " Reload autoload scripts
    for l:file in [s:file]
          \ + split(globpath(fnamemodify(s:file, ':r'), '*.vim'), '\n')
      execute 'source' l:file
    endfor

    " Reload plugin
    if exists('g:vimwiki_loaded')
      unlet g:vimwiki_loaded
      runtime plugin/vimwiki.vim
    endif

    " Reload ftplugin and syntax
    if &filetype == 'vimwiki'
      unlet b:did_ftplugin
      runtime ftplugin/vimwiki.vim

      if get(b:, 'current_syntax', '') ==# 'vimwiki'
        unlet b:current_syntax
        runtime syntax/vimwiki.vim
      endif
    endif

    unlet s:reloading_script
  endfunction
endif

" }}}1

" vim: fdm=marker sw=2
