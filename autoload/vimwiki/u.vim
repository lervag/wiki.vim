" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#u#trim(string, ...) "{{{1
  let chars = ''
  if a:0 > 0
    let chars = a:1
  endif
  let res = substitute(a:string, '^[[:space:]'.chars.']\+', '', '')
  let res = substitute(res, '[[:space:]'.chars.']\+$', '', '')
  return res
endfunction

"}}}1
function! vimwiki#u#count_first_sym(line) "{{{1
  let first_sym = matchstr(a:line, '\S')
  return len(matchstr(a:line, first_sym.'\+'))
endfunction

"}}}1
function! vimwiki#u#escape(string) "{{{1
  return escape(a:string, '~.*[]\^$')
endfunction

"}}}1
function! vimwiki#u#reload_regexes() "{{{1
  execute 'runtime! syntax/vimwiki_'.VimwikiGet('syntax').'.vim'
endfunction

"}}}1
function! vimwiki#u#reload_omni_regexes() "{{{1
  execute 'runtime! syntax/omnipresent_syntax.vim'
endfunction

"}}}1
function! vimwiki#u#reload_regexes_custom() "{{{1
  execute 'runtime! syntax/vimwiki_'.VimwikiGet('syntax').'_custom.vim'
endfunction

"}}}1

" vim: fdm=marker sw=2
