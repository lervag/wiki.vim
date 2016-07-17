" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#link#get_at_cursor() " {{{1
  for l:m in s:matchers_all
    let l:link = s:matchstr_at_cursor(l:m.rx)
    if !empty(l:link)
      let l:match = matchstrpos(l:link.full, get(l:m, 'rx_text', ''))
      let l:link.text = l:match[0]
      if !empty(l:link.text)
        let l:link.text_c1 = l:link.c1 + l:match[1]
        let l:link.text_c2 = l:link.c1 + l:match[2] - 1
      endif
      let l:link.type = l:m.type
      let l:link.toggle = function('vimwiki#link#template_' . l:m.toggle)
      return l:m.parser(l:link)
    endif
  endfor

  return {}
endfunction

" }}}1
function! vimwiki#link#get_all(...) "{{{1
  let l:file = a:0 > 0 ? a:1 : expand('%')
  if !filereadable(l:file) | return [] | endif

  let l:links = []
  let l:lnum = 0
  for l:line in readfile(l:file)
    let l:lnum += 1
    let l:col = 0
    while 1
      let l:c1 = match(l:line, vimwiki#rx#link(), l:col) + 1
      if l:c1 == 0 | break | endif

      "
      " Create link
      "
      let l:link = {}
      let l:link.full = matchstr(l:line, vimwiki#rx#link(), l:col)
      let l:link.lnum = l:lnum
      let l:link.c1 = l:c1
      let l:link.c2 = l:c1 + strlen(l:link.full)
      let l:col = l:link.c2

      "
      " Add link details
      "
      for l:m in s:matchers_all_links
        if l:m.type ==# 'ref' | continue | endif
        if l:link.full =~# '^' . l:m.rx
          let l:link.text = matchstr(l:link.full, get(l:m, 'rx_text', ''))
          let l:link.type = l:m.type
          let l:link.toggle = function('vimwiki#link#template_' . l:m.toggle)
          call add(l:links, l:m.parser(l:link, { 'origin' : l:file }))
          break
        endif
      endfor
    endwhile
  endfor

  return l:links
endfunction

"}}}1

function! vimwiki#link#open(...) "{{{1
  let l:link = vimwiki#link#get_at_cursor()

  try
    call call(l:link.open, a:000)
  catch
    call vimwiki#link#toggle(l:link)
  endtry
endfunction

" }}}1
function! vimwiki#link#toggle(...) " {{{1
  let l:link = a:0 > 0 ? a:1 : vimwiki#link#get_at_cursor()
  if empty(l:link) | return | endif

  "
  " Use stripped url for wiki links
  "
  let l:url = get(l:link, 'scheme', '') ==# 'wiki'
        \ ? l:link.stripped
        \ : get(l:link, 'url', '')
  if empty(l:url) | return | endif

  "
  " Apply link template
  "
  let l:new = l:link.toggle(l:url, l:link.text)

  "
  " Replace current link with l:new
  "
  let l:line = getline(l:link.lnum)
  call setline(l:link.lnum,
        \ strpart(l:line, 0, l:link.c1-1) . l:new . strpart(l:line, l:link.c2))
endfunction

" }}}1
function! vimwiki#link#toggle_visual() " {{{1
  "
  " Note: This function assumes that it is called from visual mode.
  "
  call vimwiki#link#toggle({
        \ 'url' : getreg('*'),
        \ 'text' : '',
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : getpos("'>")[2],
        \ 'toggle' : function('vimwiki#link#template_word'),
        \})
endfunction

" }}}1
function! vimwiki#link#toggle_operator(type, ...) " {{{1
  "
  " Note: This function assumes that it is called as an operator.
  "

  let l:save = @@
  silent execute 'normal! `[v`]y'
  let l:word = substitute(@@, '\s\+$', '', '')
  let l:diff = strlen(@@) - strlen(l:word)
  let @@ = l:save

  call vimwiki#link#toggle({
        \ 'url' : l:word,
        \ 'text' : '',
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : getpos("'>")[2] - l:diff,
        \ 'toggle' : function('vimwiki#link#template_word'),
        \})
endfunction

" }}}1

function! s:matchstr_at_cursor(regex) " {{{1
  let l:lnum = line('.')
  let l:c1 = searchpos(a:regex, 'ncb',  l:lnum)[1]
  let l:c2 = searchpos(a:regex, 'nce',  l:lnum)[1]
  if l:c1 == 0 || l:c2 == 0 | return {} | endif

  let l:c1e = searchpos(a:regex, 'ncbe', l:lnum)[1]
  if l:c1e > l:c1 && l:c1e < col('.') | return {} | endif

  return {
        \ 'full' : strpart(getline('.'), l:c1-1, l:c2-l:c1+1),
        \ 'lnum' : l:lnum,
        \ 'c1' : l:c1,
        \ 'c2' : l:c2,
        \}
endfunction

"}}}1

"
" Templates translate url and possibly text into an appropriate link
"
function! vimwiki#link#template_wiki(url, ...) " {{{1
  let l:text = a:0 > 0 ? a:1 : ''
  return empty(l:text)
        \ ? '[[' . a:url . ']]'
        \ : '[[' . a:url . '|' . l:text . ']]'
endfunction

" }}}1
function! vimwiki#link#template_md(url, ...) " {{{1
  let l:text = a:0 > 0 ? a:1 : ''
  if empty(l:text)
    let l:text = input('Link text: ')
  endif
  return '[' . l:text . '](' . a:url . ')'
endfunction

" }}}1
function! vimwiki#link#template_word(url, ...) " {{{1
  "
  " This template returns a wiki template for the provided word(s). It does
  " a smart search for likely candidates and if there is no unique match, it
  " asks for target link.
  "

  "
  " First try local page
  "
  if filereadable(expand('%:p:h') . '/' . a:url . '.wiki')
    return vimwiki#link#template_wiki(a:url)
  endif

  "
  " Next try at wiki root
  "
  if filereadable(g:vimwiki.root . a:url . '.wiki')
    return vimwiki#link#template_wiki('/' . a:url)
  endif

  "
  " Finally we see if there are completable candidates
  "
  let l:candidates = map(
        \ glob(g:vimwiki.root . a:url . '*.wiki', 0, 1),
        \ 'fnamemodify(v:val, '':t:r'')')

  "
  " Solve trivial cases first
  "
  if len(l:candidates) == 0
    return vimwiki#link#template_wiki('/' . a:url)
  elseif len(l:candidates) == 1
    return vimwiki#link#template_wiki('/' . l:candidates[0], a:url)
  endif

  "
  " Finally we ask for user input to choose desired candidate
  "
  while 1
    redraw
    "
    " The list doesn't show for operator mapping unless I print it as one long
    " string
    "
    let l:echo = ''
    for l:i in range(len(l:candidates))
      let l:echo .= '[' . (l:i + 1) . '] ' . l:candidates[l:i] . "\n"
    endfor
    echo l:echo . '[n] New page at wiki root: ' . a:url
    let l:choice = input('Choice: ')

    if l:choice ==# 'n'
      return vimwiki#link#template_wiki('/' . a:url)
    endif

    try
      let l:cand = l:candidates[l:choice - 1]
      redraw!
      return vimwiki#link#template_wiki('/' . l:cand, a:url)
    catch
      continue
    endtry
  endwhile
endfunction

" }}}1
function! vimwiki#link#template_ref(...) " {{{1
  return call('vimwiki#link#template_wiki', a:000)
endfunction

" }}}1
function! vimwiki#link#template_ref_target(url, ...) " {{{1
  let l:id = a:0 > 0 ? a:1 : ''
  if empty(l:id)
    let l:id = input('Input id: ')
  endif
  return '[' . l:id . '] ' . a:url
endfunction

" }}}1

"
" Link matchers are the matcher objects used to parse and create links
"
" {{{1 Link matchers

function! vimwiki#link#get_matcher(name) " {{{2
  return s:matcher_{a:name}
endfunction

" }}}2
function! vimwiki#link#get_matcher_opt(name, opt) " {{{2
  return escape(s:matcher_{a:name}[a:opt], '')
endfunction

" }}}2
function! vimwiki#link#get_matchers() " {{{2
  return copy(s:matchers_all)
endfunction

" }}}2
function! vimwiki#link#get_matchers_links() " {{{2
  return copy(s:matchers_all_links)
endfunction

" }}}2

function! s:parser_general(link, ...) dict " {{{2
  return extend(a:link, call('vimwiki#url#parse',
        \ [matchstr(a:link.full, get(self, 'rx_url', get(self, 'rx')))]
        \ + a:000))
endfunction

" }}}2
function! s:parser_date(link, ...) dict " {{{2
  return extend(a:link, call('vimwiki#url#parse',
        \ ['diary:' . a:link.full] + a:000))
endfunction

" }}}2
function! s:parser_word(link, ...) dict " {{{2
  return extend(a:link, {
        \ 'scheme' : '',
        \ 'url' : a:link.full,
        \})
endfunction

" }}}2
function! s:parser_ref(link, ...) dict " {{{2
  let l:id = matchstr(a:link.full, self.rx_id)
  let l:lnum = searchpos('^\[' . l:id . '\]: ', 'nW')[0]
  if l:lnum == 0
    return a:link
  else
    let l:url = matchstr(getline(l:lnum), s:rx_url)
    return extend(a:link, call('vimwiki#url#parse', [l:url] + a:000))
  endif
endfunction

" }}}2

" {{{2 Define the matchers

" Common url regex
let s:rx_url = '\<\l\+:\%(\/\/\)\?[^ \t()\[\]|]\+'

let s:matcher_wiki = {
      \ 'type' : 'wiki',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'md',
      \ 'rx'      : '\[\[\/\?[^\\\]]\{-}\%(|[^\\\]]\{-}\)\?\]\]',
      \ 'rx_url'  : '\[\[\zs\/\?[^\\\]]\{-}\ze\%(|[^\\\]]\{-}\)\?\]\]',
      \ 'rx_text' : '\[\[\/\?[^\\\]]\{-}|\zs[^\\\]]\{-}\ze\]\]',
      \}

let s:matcher_md = {
      \ 'type' : 'md',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'wiki',
      \ 'rx'      : '\[[^\\\[\]]\{-}\]([^\\]\{-})',
      \ 'rx_url'  : '\[[^\\\[\]]\{-}\](\zs[^\\]\{-}\ze)',
      \ 'rx_text' : '\[\zs[^\\\[\]]\{-}\ze\]([^\\]\{-})',
      \}

let s:matcher_ref = {
      \ 'type' : 'ref',
      \ 'parser' : function('s:parser_ref'),
      \ 'toggle' : 'ref',
      \ 'rx' : '[\]\[]\@<!\['
      \   . '[^\\\[\]]\{-}\]\[\%([^\\\[\]]\{-}\)\?'
      \   . '\][\]\[]\@!',
      \ 'rx_id' : '[\]\[]\@<!\['
      \   . '\%(\zs[^\\\[\]]\{-}\ze\]\[\|[^\\\[\]]\{-}\]\[\zs[^\\\[\]]\{-1,}\ze\)'
      \   . '\][\]\[]\@!',
      \ 'rx_text' : '[\]\[]\@<!\['
      \   . '\zs[^\\\[\]]\{-}\ze\]\[[^\\\[\]]\{-1,}'
      \   . '\][\]\[]\@!',
      \}

let s:matcher_ref_simple = {
      \ 'type' : 'ref',
      \ 'parser' : function('s:parser_ref'),
      \ 'toggle' : 'ref',
      \ 'rx' : '[\]\[]\@<!\[[^\\\[\]]\{-}\][\]\[]\@!',
      \ 'rx_id' : '\[\zs[^\\\[\]]\{-}\ze\]',
      \}

let s:matcher_ref_target = {
      \ 'type' : 'ref_target',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'ref_target',
      \ 'rx' : '\[[^\\\]]\{-}\]:\s\+' . s:rx_url,
      \ 'rx_url' : '\[[^\\\]]\{-}\]:\s\+\zs' . s:rx_url . '\ze',
      \ 'rx_text' : '\[\zs[^\\\]]\{-}\ze\]:\s\+' . s:rx_url,
      \}

let s:matcher_url = {
      \ 'type' : 'url',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'md',
      \ 'rx'     : s:rx_url,
      \}

let s:matcher_date = {
      \ 'type' : 'date',
      \ 'parser' : function('s:parser_date'),
      \ 'toggle' : 'wiki',
      \ 'rx' : '\d\d\d\d-\d\d-\d\d',
      \}

let s:matcher_word = {
      \ 'type' : 'word',
      \ 'parser' : function('s:parser_word'),
      \ 'toggle' : 'word',
      \ 'rx' : '\<\w\+\>',
      \}

let s:matchers_all_links = [
      \ s:matcher_wiki,
      \ s:matcher_md,
      \ s:matcher_ref_target,
      \ s:matcher_ref_simple,
      \ s:matcher_ref,
      \ s:matcher_url,
      \]

let s:matchers_all = copy(s:matchers_all_links)
      \ + [s:matcher_date, s:matcher_word]

" }}}2

" }}}1

"
" Old code for opening ref type links
"
function! s:url_open_ref_tmp(...) dict " {{{1
"   if !has_key(b:vimwiki, 'reflinks')
"     let b:vimwiki.reflinks = {}

"     try
"       " Why noautocmd? Because https://github.com/vimwiki/vimwiki/issues/121
"       noautocmd execute 'vimgrep #'
"         \ . g:vimwiki.link_matchers.ref_target.rx . '#j %'
"     catch /^Vim\%((\a\+)\)\=:E480/
"     endtry

"     for d in getqflist()
"       let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
"       let descr = matchstr(matchline, g:vimwiki.link_matchers.ref_target.rx_text)
"       let url = matchstr(matchline, g:vimwiki.link_matchers.ref_target.rx_url)
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
