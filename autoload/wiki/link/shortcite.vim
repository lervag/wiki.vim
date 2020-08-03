" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#shortcite#matcher() abort " {{{1
  return deepcopy(s:matcher)
endfunction

" }}}1

let s:matcher = {
      \ 'type' : 'url',
      \ 'rx' : wiki#rx#link_shortcite,
      \}

function! s:matcher.parse(link) abort dict " {{{1
  return extend(a:link, wiki#url#parse('zot:' . strpart(a:link.full, 1),
        \ has_key(a:link, 'origin') ? {'origin': a:link.origin} : {}))
endfunction

" }}}1
