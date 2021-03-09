" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#adoc_bracket#matcher() abort " {{{1
  return {
        \ 'type' : 'adoc_bracket',
        \ 'scheme' : 'adoc',
        \ 'rx' : g:wiki#rx#link_adoc_bracket,
        \ 'rx_url' : '<<\zs\%([^,>]\{-}\ze,[^>]\{-}\|[^>]\{-}\ze\)>>',
        \ 'rx_text' : '<<[^,>]\{-},\zs[^>]\{-}\ze>>',
        \}
endfunction

" }}}1
function! wiki#link#adoc_bracket#template(url, text) abort " {{{1
  let l:parts = split(a:url, '#')

  let l:url = l:parts[0]
  if a:url !~# '\.adoc$'
    let l:url .= '.adoc'
  endif

  let l:anchors = len(l:parts) > 1
        \ ? join(l:parts[1:], '#')
        \ : ''

  return printf('<<%s#%s,%s>>',
        \ l:url, l:anchors, empty(a:text) ? a:url : a:text)
endfunction

" }}}1
