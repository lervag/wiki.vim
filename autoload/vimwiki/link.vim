" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" TODO
" - reference links don't work
" - Toggle targets in diary
"

function! vimwiki#link#get_at_cursor() " {{{1
  "
  " Try to match link at cursor position
  "
  for [l:key, l:m] in items(g:vimwiki.link_matcher)
    let l:link = s:matchlink_at_cursor(l:m, l:key)
    if !empty(l:link)
      return extend(vimwiki#url#parse(l:link.url), l:link)
    endif
  endfor

  "
  " Match ISO dates as diary links
  "
  let l:url = s:matchstr_at_cursor('\d\d\d\d-\d\d-\d\d')
  if !empty(l:url)
    return vimwiki#url#parse('diary:' . l:url)
  endif

  return {}
endfunction

" }}}1
function! vimwiki#link#follow(...) "{{{1
  let l:link = vimwiki#link#get_at_cursor()

  if empty(l:link)
    call vimwiki#link#toggle()
  else
    call call(l:link.open, a:000)
  endif
endfunction

" }}}1
function! vimwiki#link#toggle() " {{{1
  let l:link = vimwiki#link#get_at_cursor()

  "
  " Trivial case
  "
  if empty(l:link)
    normal! viwy
    call vimwiki#link#toggle_visual()
  endif

  "
  " Get link type
  "
  let l:type = get(l:link, 'type', '')
  if empty(l:type)    | return | endif
  if l:type ==# 'ref' | return | endif

  "
  " Choose url version
  "
  let l:url = l:link.scheme ==# 'wiki' ? l:link.stripped : l:link.url

  "
  " Get replace string
  "
  if l:type ==# 'md'
    if empty(l:link.text)
      let l:parts = split(g:vimwiki.link_matcher.wiki.template[0], '__Url__')
      let l:new = l:parts[0] . l:url . l:parts[1]
    else
      let l:parts = split(g:vimwiki.link_matcher.wiki.template[1],
            \ '__Url__\|__Text__')
      let l:new = l:parts[0] . l:url . l:parts[1] . l:link.text . l:parts[2]
    endif
  elseif l:type ==# 'wiki'
    if empty(l:link.text)
      let l:new = l:url
    else
      let l:parts = split(g:vimwiki.link_matcher.md.template, '__Url__\|__Text__')
      let l:new = l:parts[0] . l:link.text . l:parts[1] . l:url . l:parts[2]
    endif
  elseif l:type ==# 'url'
    let l:parts = split(g:vimwiki.link_matcher.md.template, '__Url__\|__Text__')
    let l:new = l:parts[0] . 'XXX' . l:parts[1] . l:url . l:parts[2]
  endif

  "
  " Replace current link with l:new
  "
  let l:line = getline(l:link.lnum)
  call setline(l:link.lnum, strpart(l:line, 0, l:link.cnum1-1)
        \ . l:new . strpart(l:line, l:link.cnum2))
endfunction

" }}}1
function! vimwiki#link#toggle_visual() " {{{1
  "
  " Note: This function assumes that it is called from visual mode.
  "
  let l:parts = split(g:vimwiki.link_matcher.wiki.template[0], '__Url__')
  let l:link = l:parts[0] . getreg('*') . l:parts[1]

  let l:line = getline('.')
  let l:c1 = getpos("'<")[2]
  let l:c2 = getpos("'>")[2]
  call setline('.', strpart(l:line, 0, l:c1-1) . l:link . strpart(l:line, l:c2))
endfunction

" }}}1

function! s:matchstr_at_cursor(regex) " {{{1
  let l:c1 = searchpos(a:regex, 'ncb', line('.'))[1]
  let l:c2 = searchpos(a:regex, 'nce', line('.'))[1]

  return (l:c1 > 0) && (l:c2 > 0)
        \ ? strpart(getline('.'), l:c1-1, l:c2)
        \ : ''
endfunction

"}}}1
function! s:matchlink_at_cursor(matcher, type) " {{{1
  let l:lnum = line('.')

  let l:cnum1 = searchpos(a:matcher.rx_full, 'ncb', l:lnum)[1]
  let l:cnum2 = searchpos(a:matcher.rx_full, 'nce', l:lnum)[1]

  if (l:cnum1 == 0) || (l:cnum2 == 0) | return {} | endif
  let l:link = strpart(getline('.'), l:cnum1-1, l:cnum2)

  return {
        \ 'link' : l:link,
        \ 'type' : a:type,
        \ 'url' : matchstr(l:link, a:matcher.rx_url),
        \ 'text' : matchstr(l:link, a:matcher.rx_text),
        \ 'lnum' : l:lnum,
        \ 'cnum1' : l:cnum1,
        \ 'cnum2' : l:cnum2,
        \}
endfunction

"}}}1

"
" Old code for opening ref type links
"
function! s:url_open_ref_tmp(...) dict " {{{1
"   if !has_key(b:vimwiki, 'reflinks')
"     let b:vimwiki.reflinks = {}

"     try
"       " Why noautocmd? Because https://github.com/vimwiki/vimwiki/issues/121
"       noautocmd execute 'vimgrep #'
"         \ . g:vimwiki.link_matcher.ref_target.rx_full . '#j %'
"     catch /^Vim\%((\a\+)\)\=:E480/
"     endtry

"     for d in getqflist()
"       let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
"       let descr = matchstr(matchline, g:vimwiki.link_matcher.ref_target.rx_text)
"       let url = matchstr(matchline, g:vimwiki.link_matcher.ref_target.rx_url)
"       if descr != '' && url != ''
"         let b:vimwiki.reflinks[descr] = url
"       endif
"     endfor
"   endif

"   if has_key(b:vimwiki.reflinks, self.url)
"     call s:url_open_external(b:vimwiki.reflinks[self.url])
"   endif
endfunction

"}}}1

" vim: fdm=marker sw=2
