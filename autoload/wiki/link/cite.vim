" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#cite#matcher() abort " {{{1
  return extend(wiki#link#_template#matcher(), deepcopy(s:matcher))
endfunction

" }}}1


let s:matcher = {
      \ 'type': 'cite',
      \ 'rx': wiki#rx#link_cite,
      \ 'rx_url': wiki#rx#link_cite_url,
      \}
