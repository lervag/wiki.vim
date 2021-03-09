" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#adoc_link#matcher() abort " {{{1
  return deepcopy(s:matcher)
endfunction

" }}}1

let s:matcher = {
      \ 'type' : 'adoc_link',
      \ 'rx' : g:wiki#rx#link_adoc_link,
      \ 'rx_url' : '\<link:\%(\[\zs[^]]\+\ze\]\|\zs[^[]\+\ze\)\[[^]]\+\]',
      \ 'rx_text' : '\<link:\%(\[[^]]\+\]\|[^[]\+\)\[\zs[^]]\+\ze\]',
      \}

function! s:matcher.parse(link) abort dict " {{{1
  if empty(matchstr(a:link.url, '\v^\w+:%(//)?'))
    let a:link.url = 'file:' . a:link.url
  endif
  return extend(a:link, wiki#url#parse(a:link.url,
        \ has_key(a:link, 'origin') ? {'origin': a:link.origin} : {}))
endfunction

" }}}1
