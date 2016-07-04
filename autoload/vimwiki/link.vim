" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" TODO
" - reference links don't work
" - Add normlize_link_in_diary?
"

function! vimwiki#link#get_at_cursor() " {{{1
  "
  " Try to match link at cursor position
  "
  for [l:key, l:m] in items(g:vimwiki.link_matcher)
    let l:link = s:matchlink_at_cursor(l:m, l:key)
    if !empty(l:link)
      return extend(vimwiki#link#parse(l:link.url), l:link)
    endif
  endfor

  "
  " Match ISO dates as diary links
  "
  let l:url = s:matchstr_at_cursor('\d\d\d\d-\d\d-\d\d')
  if !empty(l:url)
    return vimwiki#link#parse('diary:' . l:url)
  endif

  return {}
endfunction

" }}}1
function! vimwiki#link#parse(url, ...) " {{{1
  let l:options = a:0 > 0 ? a:1 : {}

  let l:link = {}
  let l:link.url = a:url
  let l:link.origin = get(l:options, 'origin', expand('%:p'))

  " Decompose link into its scheme and link text
  let l:link_parts = matchlist(a:url, '\v((\w+):%(//)?)?(.*)')
  let l:link.stripped = l:link_parts[3]
  if empty(l:link_parts[2])
    let l:link.scheme = 'wiki'
    let l:link.url = l:link.scheme . ':' . a:url
  else
    let l:link.scheme = l:link_parts[2]
  endif

  let l:link_parsed = get({
        \   'wiki':  s:parse_link_wiki(l:link),
        \   'diary': s:parse_link_wiki(l:link),
        \   'file':  s:parse_link_file(l:link),
        \   'doi':   s:parse_link_doi(l:link),
        \ }, l:link.scheme, s:parse_link_external(l:link))

  return extend(l:link, l:link_parsed, 'force')
endfunction

" }}}1
function! vimwiki#link#follow(...) "{{{1
  let l:link = vimwiki#link#get_at_cursor()

  if empty(l:link)
    call vimwiki#link#toggle()
  else
    call call(l:link.follow, a:000)
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
  let l:save_reg = @a
  let l:parts = split(g:vimwiki.link_matcher.wiki.template[0], '__Url__')
  let l:link = l:parts[0] . getreg('*') . l:parts[1]
  call setreg('a', l:link, 'v')
  normal! gvd"aP
  call setreg('a', l:save_reg)
endfunction

" }}}1

function! s:parse_link_wiki(link) " {{{1
  let l:link = {}
  let l:link.follow = function('s:follow_link_wiki')

  " Parse link anchor
  let l:anchors = split(a:link.stripped, '#', 1)
  let l:link.anchor = (len(l:anchors) > 1) && (l:anchors[-1] != '')
        \ ? join(l:anchors[1:], '#') : ''
  let l:fname = !empty(l:anchors[0]) ? l:anchors[0]
        \ : fnamemodify(a:link.origin, ':p:t:r')

  " Extract target filename (full path)
  if a:link.scheme ==# 'diary'
    let l:link.scheme = 'wiki'
    let l:link.filename = g:vimwiki.diary . l:fname . '.wiki'
  else
    if l:fname[0] == '/'
      let l:fname = strpart(l:fname, 1)
      let l:link.filename = g:vimwiki.root . l:fname . '.wiki'
    else
      let l:link.filename = fnamemodify(a:link.origin, ':p:h') . '/'
            \ . l:fname . '.wiki'
    endif
  endif

  return l:link
endfunction

" }}}1
function! s:parse_link_file(link) " {{{1
  if a:link.stripped[0] ==# '/'
    let l:filename = a:link.stripped
  elseif a:link.stripped =~# '\~\w*\/'
    let l:filename = simplify(fnamemodify(a:link.stripped, ':p'))
  else
    let l:filename = simplify(
          \ fnamemodify(a:link.origin, ':p:h') . '/' . a:link.stripped)
  endif

  return { 'follow' : function('s:follow_link_file'),
        \  'filename' : l:filename }
endfunction

" }}}1
function! s:parse_link_doi(link) " {{{1
  return {
        \ 'scheme' : 'http',
        \ 'stripped' : 'dx.doi.org/' . a:link.stripped,
        \ 'url' : 'http://dx.doi.org/' . a:link.stripped,
        \ 'follow' : function('s:follow_link_external'),
        \}
endfunction

" }}}1
function! s:parse_link_external(link) " {{{1
  return { 'follow' : function('s:follow_link_external') }
endfunction

" }}}1

function! s:follow_link_wiki(...) dict " {{{1
  let l:opts = {}
  let l:opts.cmd = a:0 > 0 ? a:1 : 'edit'
  let l:opts.anchor = self.anchor

  if resolve(self.filename) !=# resolve(expand('%:p'))
    if a:0 > 1
      let l:opts.prev_link = [a:2, []]
    elseif &ft ==# 'vimwiki'
      let l:opts.prev_link = [expand('%:p'), getpos('.')]
    endif
  endif

  call vimwiki#edit_file(self.filename, l:opts)

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
"     call s:follow_link_external(b:vimwiki.reflinks[self.url])
"   endif
endfunction

"}}}1
function! s:follow_link_file(...) dict " {{{1
  if isdirectory(self.filename)
    execute 'Unite file:' . self.filename
    return
  endif

  if !filereadable(self.filename) | return | endif

  if self.filename =~# 'pdf$'
    silent execute '!zathura' self.filename '&'
    return
  endif

  execute 'edit' self.filename
endfunction

"}}}1
function! s:follow_link_external(...) dict " {{{1
  call system('xdg-open ' . shellescape(self.url) . '&')
endfunction

"}}}1

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

" vim: fdm=marker sw=2
