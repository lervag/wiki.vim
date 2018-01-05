" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! s:url_parser_doi(url) abort " {{{1
  let l:url = {
        \ 'scheme' : 'http',
        \ 'stripped' : 'dx.doi.org/' . a:url.stripped,
        \ 'url' : 'http://dx.doi.org/' . a:url.stripped,
        \}

  return extend(l:url, wiki#url#generic#parse(l:res))
endfunction

" }}}1
