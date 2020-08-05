" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#wiki#matcher() abort " {{{1
  return {
        \ 'type' : 'wiki',
        \ 'rx' : g:wiki#rx#link_wiki,
        \ 'rx_url' : '\[\[\zs\/\?[^\\\]]\{-}\ze\%(|[^\\\]]\{-}\)\?\]\]',
        \ 'rx_text' : '\[\[\/\?[^\\\]]\{-}|\zs[^\\\]]\{-}\ze\]\]',
        \}
endfunction

" }}}1
function! wiki#link#wiki#template(url, text) abort " {{{1
  return empty(a:text) || a:text ==# a:url || a:text ==# a:url[1:]
        \ ? '[[' . a:url . ']]'
        \ : '[[' . a:url . '|' . a:text . ']]'
endfunction

" }}}1
