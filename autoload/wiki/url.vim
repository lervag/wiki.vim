" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#parse(string, ...) abort " {{{1
  "
  " The following is a description of a typical url object
  "
  "   url = {
  "     'string'   : The original url string (unaltered)
  "     'url'      : The full url (after parsing)
  "     'scheme'   : The scheme of the url
  "     'stripped' : The url without the preceding scheme
  "     'origin'   : Where the url originates
  "     'open'     : Method to open the url
  "   }
  "
  let l:options = a:0 > 0 ? a:1 : {}

  let l:url = {}
  let l:url.string = a:string
  let l:url.url = a:string
  let l:url.origin = get(l:options, 'origin', expand('%:p'))

  " Decompose string into its scheme and stripped url
  let l:parts = matchlist(a:string, '\v((\w+):%(//)?)?(.*)')
  let l:url.stripped = l:parts[3]
  if empty(l:parts[2])
    let l:url.scheme = 'wiki'
    let l:url.url = l:url.scheme . ':' . a:string
  else
    let l:url.scheme = l:parts[2]
  endif

  try
    call extend(l:url, wiki#url#{tolower(l:url.scheme)}#parse(l:url))
  catch /E117:/
    call extend(l:url, wiki#url#generic#parse(l:url))
  endtry

  return l:url
endfunction

" }}}1
function! wiki#url#extend(link) abort " {{{1
  let l:options = has_key(a:link, 'origin')
        \ ? {'origin': a:link.origin}
        \ : {}

  return extend(a:link, wiki#url#parse(a:link.url, l:options))
endfunction

" }}}1
