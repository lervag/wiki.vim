" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#md_fig#matcher() abort " {{{1
  return deepcopy(s:matcher)
endfunction

" }}}1

let s:matcher = {
        \ 'type' : 'md_fig',
        \ 'rx' : g:wiki#rx#link_md_fig,
        \ 'rx_url' : '!\[[^\\\[\]]\{-}\](\zs[^\\]\{-}\ze)',
        \ 'rx_text' : '!\[\zs[^\\\[\]]\{-}\ze\]([^\\]\{-})',
        \}

function! s:matcher.parse(link) abort dict " {{{1
  return extend(a:link, wiki#url#parse('file://' . a:link.url,
        \ has_key(a:link, 'origin') ? {'origin': a:link.origin} : {}))
endfunction

" }}}1
function! s:matcher.toggle(url, text) abort " {{{1
  return printf('![%s](%s)', empty(a:text) ? a:url : a:text, a:url)
endfunction

" }}}1
