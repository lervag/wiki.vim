" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#journal#parse(url) abort " {{{1
  let a:url.scheme = 'wiki'
  let a:url.stripped = printf('/%s/%s', g:wiki_journal.name, a:url.stripped)

  return wiki#url#wiki#parse(a:url)
endfunction

" }}}1
