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

function! vimwiki#define_regexes() " {{{
  let g:vimwiki_markdown_header_search = '^\s*\(#\{1,6}\)\([^#].*\)$'
  let g:vimwiki_markdown_header_match = '^\s*\(#\{1,6}\)#\@!\s*__Header__\s*$'
  let g:vimwiki_markdown_bold_search = '\%(^\|\s\|[[:punct:]]\)\@<=\*\zs\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)\ze\*\%([[:punct:]]\|\s\|$\)\@='
  let g:vimwiki_markdown_bold_match = '\%(^\|\s\|[[:punct:]]\)\@<=\*__Text__\*\%([[:punct:]]\|\s\|$\)\@='
  let g:vimwiki_markdown_wikilink = '\[\[\zs[^\\\]|]\+\ze\%(|[^\\\]]\+\)\?\]\]'
  let g:vimwiki_markdown_tag_search = '\(^\|\s\)\zs:\([^:''[:space:]]\+:\)\+\ze\(\s\|$\)'
  let g:vimwiki_markdown_tag_match = '\(^\|\s\):\([^:''[:space:]]\+:\)*__Tag__:\([^:[:space:]]\+:\)*\(\s\|$\)'

  let g:vimwiki_rxWeblinkUrl =
        \ '\%(\%(\%(' . join(split(g:vimwiki_web_schemes1, '\s*,\s*'), '\|')
        \ . '\):\%(//\)\)'
        \ . '\|\%(' . join(split(g:vimwiki_web_schemes2, '\s*,\s*'), '\|')
        \ . '\):\)'
        \ . '\S\{-1,}\%(([^ \t()]*)\)\='

  let g:vimwiki_rxH = '#'
  let g:vimwiki_symH = 0

  let g:vimwiki_bullet_types = { '-':0, '*':0, '+':0 }
  let g:vimwiki_number_types = ['1.']
  let g:vimwiki_list_markers = ['-', '*', '+', '1.']
  call vimwiki#lst#setup_marker_infos()

  let g:vimwiki_rxListItemWithoutCB = '^\s*\%(\('.g:vimwiki_rxListBullet.'\)\|\('.g:vimwiki_rxListNumber.'\)\)\s'
  let g:vimwiki_rxListItem = g:vimwiki_rxListItemWithoutCB . '\+\%(\[\(['.g:vimwiki_listsyms.']\)\]\s\)\?'

  let g:vimwiki_rxPreStart = '```'
  let g:vimwiki_rxPreEnd = '```'

  let g:vimwiki_rxMathStart = '\$\$'
  let g:vimwiki_rxMathEnd = '\$\$'
endfunction

" }}}1

" vim: fdm=marker sw=2
