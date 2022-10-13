" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#parse(url, ...) abort " {{{1
  " This function parses a URL and returns a URL handler.

  " The URL scheme specifies the desired handler with a generic handler as
  " a fallback. The handler is created with the following input:
  "
  "   url = {
  "     'origin':   Where the url originates
  "     'scheme':   The scheme of the url
  "     'stripped': The url without the preceding scheme
  "     'url':      The full url
  "   }
  let l:url = s:parse_url(a:url, a:0 > 0 ? a:1 : expand('%:p'))

  " A handler is a dictionary object:
  "
  "   handler = {
  "     'follow': Method to follow the url
  "     '...':    Necessary state vars
  "   }
  try
    let l:handler = wiki#url#{l:url.scheme}#handler(l:url)
  catch /E117:/
    let l:handler = wiki#url#generic#handler(l:url)
  endtry

  let l:handler.scheme = l:url.scheme
  return l:handler
endfunction

" }}}1
function! wiki#url#extend(link) abort " {{{1
  return extend(a:link,
        \ wiki#url#parse(a:link.url, a:link.filename))
endfunction

" }}}1

function! s:parse_url(url, origin) abort " {{{1
  let l:url = {}
  let l:url.url = a:url
  let l:url.origin = a:origin

  " Decompose the url into its scheme and stripped url
  let l:parts = matchlist(l:url.url, '\v((\w+):%(//)?)?(.*)')
  let l:url.stripped = l:parts[3]
  if empty(l:parts[2])
    let l:url.scheme = 'wiki'
    let l:url.url = l:url.scheme . ':' . l:url.url
  else
    let l:url.scheme = tolower(l:parts[2])
  endif

  return l:url
endfunction

" }}}1
