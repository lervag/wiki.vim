" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#adoc_xref_bracket#matcher() abort " {{{1
  return extend(wiki#link#_template#matcher(), {
        \ 'type': 'adoc_xref_bracket',
        \ 'scheme': 'adoc',
        \ 'rx': g:wiki#rx#link_adoc_xref_bracket,
        \ 'rx_url': '<<\zs\%([^,>]\{-}\ze,[^>]\{-}\|[^>]\{-}\ze\)>>',
        \ 'rx_text': '<<[^,>]\{-},\zs[^>]\{-}\ze>>',
        \})
endfunction

" }}}1
function! wiki#link#adoc_xref_bracket#template(url, text) abort " {{{1
  let l:parts = split(a:url, '#')
  let l:anchors = len(l:parts) > 1
        \ ? join(l:parts[1:], '#')
        \ : ''

  " Ensure there's an extension
  let l:url = l:parts[0]
  if l:url !~# '\.adoc$'
    let l:url .= '.adoc'
  endif
  let l:url .= '#' . l:anchors

  return printf('<<%s,%s>>', l:url, empty(a:text) ? a:url : a:text)
endfunction

" }}}1
