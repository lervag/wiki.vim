" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#url#matcher() abort " {{{1
  return extend(wiki#link#_template#matcher(), deepcopy(s:matcher))
endfunction

" }}}1


let s:matcher = {
      \ 'type': 'url',
      \ 'rx': g:wiki#rx#url,
      \}
