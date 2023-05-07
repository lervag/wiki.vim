" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#md#matcher() abort " {{{1
  return extend(wiki#link#_template#matcher(), deepcopy(s:matcher))
endfunction

" }}}1
function! wiki#link#md#template(url, text) abort " {{{1
  return printf('[%s](%s)', empty(a:text) ? a:url : a:text, a:url)
endfunction

" }}}1


let s:matcher = {
      \ 'type': 'md',
      \ 'rx': g:wiki#rx#link_md,
      \ 'rx_url': '\[[^[\]]\{-}\](\zs[^\\]\{-}\ze)',
      \ 'rx_text': '\[\zs[^[\]]\{-}\ze\]([^\\]\{-})',
      \}
