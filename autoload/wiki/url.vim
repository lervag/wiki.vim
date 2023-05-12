" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#follow(url_string, ...) abort " {{{1
  let l:url = wiki#url#resolve(a:url_string)
  if empty(l:url) | return | endif

  if g:wiki_write_on_nav | update | endif

  try
    let l:edit_cmd = a:0 > 0 ? a:1 : 'edit'
    call wiki#url#handlers#{l:url.scheme}(l:url, l:edit_cmd)
  catch /E117/
    call wiki#url#handlers#generic(l:url)
  endtry
endfunction

" }}}1
function! wiki#url#resolve(url_string, ...) abort " {{{1
  let l:parts = matchlist(a:url_string, '\v%((\w+):)?(.*)')

  let l:url = {
        \ 'url': a:url_string,
        \ 'scheme': tolower(l:parts[1]),
        \ 'stripped': l:parts[2],
        \ 'origin': a:0 > 0 ? a:1 : expand('%:p'),
        \}

  " The wiki scheme is default if no other scheme is applied
  if empty(l:url.scheme)
    let l:url.scheme = 'wiki'
    let l:url.url = l:url.scheme . ':' . l:url.url
  endif

  try
    let l:url = wiki#url#resolvers#{l:url.scheme}(l:url)
  catch /E117/
  endtry

  return l:url
endfunction

" }}}1
