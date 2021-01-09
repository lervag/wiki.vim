" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#adoc#matcher() abort " {{{1
  return {
        \ 'type' : 'adoc',
        \ 'rx' : g:wiki#rx#link_adoc,
        \ 'rx_url' : '<<\zs[^#]\{-}\ze\.adoc#,[^>]\{-}>>',
        \ 'rx_text' : '<<[^#]\{-}#,\zs[^>]\{-}\ze>>',
        \}
endfunction

" }}}1
function! wiki#link#adoc#template(url, text) abort " {{{1
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
