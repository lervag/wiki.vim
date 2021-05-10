" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#journal#handler(url) abort " {{{1
  let a:url.stripped = printf('/%s/%s', g:wiki_journal.name, a:url.stripped)
  return wiki#url#wiki#handler(a:url)
endfunction

" }}}1
