" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#adoc_link#matcher() abort " {{{1
  return extend(wiki#link#_template#matcher(), deepcopy(s:matcher))
endfunction

" }}}1


let s:matcher = {
      \ 'type': 'adoc_link',
      \ 'rx': g:wiki#rx#link_adoc_link,
      \ 'rx_url': '\<link:\%(\[\zs[^]]\+\ze\]\|\zs[^[]\+\ze\)\[[^]]\+\]',
      \ 'rx_text': '\<link:\%(\[[^]]\+\]\|[^[]\+\)\[\zs[^]]\+\ze\]',
      \}
