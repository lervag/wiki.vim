" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#adoc#matcher() abort " {{{1
  return {
        \ 'type' : 'adoc',
        \ 'rx' : g:wiki#rx#link_adoc,
        \ 'rx_url' : '<<\zs[^#]\{-}\ze#,[^>]\{-}>>',
        \ 'rx_text' : '<<[^#]\{-}#,\zs[^>]\{-}\ze>>',
        \}
endfunction

" }}}1
function! wiki#link#adoc#template(url, text) abort " {{{1
  return printf('<<%s.adoc#,%s>>', empty(a:text) ? a:url : a:text, a:url)
endfunction

" }}}1
