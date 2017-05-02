" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#get_at_cursor() " {{{1
  for l:m in wiki#link#get_matchers_all()
    let l:link = s:matchstr_at_cursor(l:m.rx)
    if !empty(l:link)
      "
      " Get link text
      "
      let l:match = s:matchstrpos(l:link.full, get(l:m, 'rx_text', ''))
      let l:link.text = l:match[0]
      if !empty(l:link.text)
        let l:link.text_c1 = l:link.c1 + l:match[1]
        let l:link.text_c2 = l:link.c1 + l:match[2] - 1
      endif

      "
      " Get link url position (if available)
      "
      if has_key(l:m, 'rx_url')
        let l:match = s:matchstrpos(l:link.full, l:m.rx_url)
        if !empty(l:match[0])
          let l:link.url_c1 = l:link.c1 + l:match[1]
          let l:link.url_c2 = l:link.c1 + l:match[2] - 1
        endif
      endif

      let l:link.type = l:m.type
      let l:link.toggle = function('wiki#link#template_' . l:m.toggle)
      return l:m.parser(l:link)
    endif
  endfor

  return {}
endfunction

function! s:matchstrpos(...) " {{{2
  if exists('*matchstrpos')
    return call('matchstrpos', a:000)
  else
    let [l:expr, l:pat] = a:000[:1]

    let l:pos = match(l:expr, l:pat)
    if l:pos < 0
      return ['', -1, -1]
    else
      let l:match = matchstr(l:expr, l:pat)
      return [l:match, l:pos, l:pos+strlen(l:match)]
    endif
  endif
endfunction

" }}}2

" }}}1
function! wiki#link#get_all(...) "{{{1
  let l:file = a:0 > 0 ? a:1 : expand('%')
  if !filereadable(l:file) | return [] | endif

  let l:links = []
  let l:lnum = 0
  for l:line in readfile(l:file)
    let l:lnum += 1
    let l:col = 0
    while 1
      let l:c1 = match(l:line, wiki#rx#link(), l:col) + 1
      if l:c1 == 0 | break | endif

      "
      " Create link
      "
      let l:link = {}
      let l:link.full = matchstr(l:line, wiki#rx#link(), l:col)
      let l:link.lnum = l:lnum
      let l:link.c1 = l:c1
      let l:link.c2 = l:c1 + strlen(l:link.full)
      let l:col = l:link.c2

      "
      " Add link details
      "
      for l:m in wiki#link#get_matchers_links()
        if l:m.type ==# 'ref' | continue | endif
        if l:link.full =~# '^' . l:m.rx
          let l:link.text = matchstr(l:link.full, get(l:m, 'rx_text', ''))
          let l:link.type = l:m.type
          let l:link.toggle = function('wiki#link#template_' . l:m.toggle)
          call add(l:links, l:m.parser(l:link, { 'origin' : l:file }))
          break
        endif
      endfor
    endwhile
  endfor

  return l:links
endfunction

"}}}1

function! wiki#link#open(...) "{{{1
  let l:link = wiki#link#get_at_cursor()

  try
    call call(l:link.open, a:000, l:link)
  catch
    call wiki#link#toggle(l:link)
  endtry
endfunction

" }}}1
function! wiki#link#toggle(...) " {{{1
  let l:link = a:0 > 0 ? a:1 : wiki#link#get_at_cursor()
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
function! wiki#link#toggle_visual() " {{{1
  normal! gv"wy
  call wiki#link#toggle({
        \ 'url' : getreg('w'),
        \ 'text' : '',
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : s:handle_multibyte(getpos("'>")[2]),
        \ 'toggle' : function('wiki#link#template_word'),
        \})
endfunction

" }}}1
function! wiki#link#toggle_operator(type, ...) " {{{1
  "
  " Note: This function assumes that it is called as an operator.
  "

  let l:save = @@
  silent execute 'normal! `[v`]y'
  let l:word = substitute(@@, '\s\+$', '', '')
  let l:diff = strlen(@@) - strlen(l:word)
  let @@ = l:save

  call wiki#link#toggle({
        \ 'url' : l:word,
        \ 'text' : '',
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : getpos("'>")[2] - l:diff,
        \ 'toggle' : function('wiki#link#template_word'),
        \})
endfunction

" }}}1

function! s:matchstr_at_cursor(regex) " {{{1
  let l:lnum = line('.')
  let l:c1 = searchpos(a:regex, 'ncb',  l:lnum)[1]
  let l:c2 = searchpos(a:regex, 'nce',  l:lnum)[1]
  if l:c1 == 0 || l:c2 == 0 | return {} | endif

  let l:c2 = s:handle_multibyte(l:c2)

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
function! s:handle_multibyte(cnum) " {{{1
  if a:cnum <= 0 | return a:cnum | endif
  let l:char = getline('.')[a:cnum-1 : a:cnum]
  return a:cnum + (strchars(l:char) == 1)
endfunction

" }}}1

"
" Templates translate url and possibly text into an appropriate link
"
function! wiki#link#template_wiki(url, ...) " {{{1
  let l:text = a:0 > 0 ? a:1 : ''
  return empty(l:text)
        \ ? '[[' . a:url . ']]'
        \ : '[[' . a:url . '|' . l:text . ']]'
endfunction

" }}}1
function! wiki#link#template_md(url, ...) " {{{1
  let l:text = a:0 > 0 ? a:1 : ''
  if empty(l:text)
    let l:text = input('Link text: ')
  endif
  return '[' . l:text . '](' . a:url . ')'
endfunction

" }}}1
function! wiki#link#template_word(url, ...) " {{{1
  "
  " This template returns a wiki template for the provided word(s). It does
  " a smart search for likely candidates and if there is no unique match, it
  " asks for target link.
  "

  "
  " First try local page
  "
  if filereadable(expand('%:p:h') . '/' . a:url . '.wiki')
    return wiki#link#template_wiki(a:url)
  endif

  "
  " Next try at wiki root
  "
  if filereadable(g:wiki.root . a:url . '.wiki')
    return wiki#link#template_wiki('/' . a:url)
  endif

  "
  " Finally we see if there are completable candidates
  "
  let l:candidates = map(
        \ glob(g:wiki.root . a:url . '*.wiki', 0, 1),
        \ 'fnamemodify(v:val, '':t:r'')')

  "
  " Solve trivial cases first
  "
  if len(l:candidates) == 0
    return wiki#link#template_wiki((b:wiki.in_journal ? '/' : '') . a:url)
  elseif len(l:candidates) == 1
    return wiki#link#template_wiki('/' . l:candidates[0], a:url)
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
      return wiki#link#template_wiki('/' . a:url)
    endif

    try
      let l:cand = l:candidates[l:choice - 1]
      redraw!
      return wiki#link#template_wiki('/' . l:cand, a:url)
    catch
      continue
    endtry
  endwhile
endfunction

" }}}1
function! wiki#link#template_ref(...) " {{{1
  return call('wiki#link#template_wiki', a:000)
endfunction

" }}}1
function! wiki#link#template_ref_target(url, ...) " {{{1
  let l:id = a:0 > 0 ? a:1 : ''
  if empty(l:id)
    let l:id = input('Input id: ')
  endif
  return '[' . l:id . '] ' . a:url
endfunction

" }}}1

"
" Methods to get matchers
"
function! wiki#link#get_matcher(name) " {{{1
  return s:matcher_{a:name}
endfunction

" }}}1
function! wiki#link#get_matcher_opt(name, opt) " {{{1
  return escape(s:matcher_{a:name}[a:opt], '')
endfunction

" }}}1
function! wiki#link#get_matchers_all() " {{{1
  return [
        \ s:matcher_wiki,
        \ s:matcher_md,
        \ s:matcher_ref_target,
        \ s:matcher_ref_simple,
        \ s:matcher_ref,
        \ s:matcher_url,
        \ s:matcher_date,
        \ s:matcher_word,
        \]
endfunction

" }}}1
function! wiki#link#get_matchers_links() " {{{1
  return [
        \ s:matcher_wiki,
        \ s:matcher_md,
        \ s:matcher_ref_target,
        \ s:matcher_ref_simple,
        \ s:matcher_ref,
        \ s:matcher_url,
        \]
endfunction

" }}}1

"
" Parsers create a proper link of a given type based on general input
"
function! s:parser_general(link, ...) dict " {{{1
  return extend(a:link, call('wiki#url#parse',
        \ [matchstr(a:link.full, get(self, 'rx_url', get(self, 'rx')))]
        \ + a:000))
endfunction

" }}}1
function! s:parser_date(link, ...) dict " {{{1
  return extend(a:link, call('wiki#url#parse',
        \ ['journal:' . a:link.full] + a:000))
endfunction

" }}}1
function! s:parser_word(link, ...) dict " {{{1
  return extend(a:link, {
        \ 'scheme' : '',
        \ 'url' : a:link.full,
        \})
endfunction

" }}}1
function! s:parser_ref(link, ...) dict " {{{1
  let l:id = matchstr(a:link.full, self.rx_id)
  let l:lnum = searchpos('^\[' . l:id . '\]: ', 'nW')[0]
  if l:lnum == 0
    return a:link
  else
    let l:url = matchstr(getline(l:lnum), s:rx_url)
    return extend(a:link, call('wiki#url#parse', [l:url] + a:000))
  endif
endfunction

" }}}1

" Common url regex
let s:rx_url = '\<\l\+:\%(\/\/\)\?[^ \t()\[\]|]\+'

"
" These are the actual matchers. Link matchers are the matcher objects used to
" parse and create links.
"
" {{{1 s:matcher_wiki
let s:matcher_wiki = {
      \ 'type' : 'wiki',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'md',
      \ 'rx'      : '\[\[\/\?[^\\\]]\{-}\%(|[^\\\]]\{-}\)\?\]\]',
      \ 'rx_url'  : '\[\[\zs\/\?[^\\\]]\{-}\ze\%(|[^\\\]]\{-}\)\?\]\]',
      \ 'rx_text' : '\[\[\/\?[^\\\]]\{-}|\zs[^\\\]]\{-}\ze\]\]',
      \}

" }}}1
" {{{1 s:matcher_md
let s:matcher_md = {
      \ 'type' : 'md',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'wiki',
      \ 'rx'      : '\[[^\\\[\]]\{-}\]([^\\]\{-})',
      \ 'rx_url'  : '\[[^\\\[\]]\{-}\](\zs[^\\]\{-}\ze)',
      \ 'rx_text' : '\[\zs[^\\\[\]]\{-}\ze\]([^\\]\{-})',
      \}

" }}}1
" {{{1 s:matcher_ref
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

" }}}1
" {{{1 s:matcher_ref_simple
let s:matcher_ref_simple = {
      \ 'type' : 'ref',
      \ 'parser' : function('s:parser_ref'),
      \ 'toggle' : 'ref',
      \ 'rx' : '[\]\[]\@<!\[[^\\\[\]]\{-}\][\]\[]\@!',
      \ 'rx_id' : '\[\zs[^\\\[\]]\{-}\ze\]',
      \}

" }}}1
" {{{1 s:matcher_ref_target
let s:matcher_ref_target = {
      \ 'type' : 'ref_target',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'ref_target',
      \ 'rx' : '\[[^\\\]]\{-}\]:\s\+' . s:rx_url,
      \ 'rx_url' : '\[[^\\\]]\{-}\]:\s\+\zs' . s:rx_url . '\ze',
      \ 'rx_text' : '\[\zs[^\\\]]\{-}\ze\]:\s\+' . s:rx_url,
      \}

" }}}1
" {{{1 s:matcher_url
let s:matcher_url = {
      \ 'type' : 'url',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'md',
      \ 'rx'     : s:rx_url,
      \}

" }}}1
" {{{1 s:matcher_date
let s:matcher_date = {
      \ 'type' : 'date',
      \ 'parser' : function('s:parser_date'),
      \ 'toggle' : 'wiki',
      \ 'rx' : '\d\d\d\d-\d\d-\d\d',
      \}

" }}}1
" {{{1 s:matcher_word
let s:matcher_word = {
      \ 'type' : 'word',
      \ 'parser' : function('s:parser_word'),
      \ 'toggle' : 'word',
      \ 'rx' : '\<[0-9A-ZÆØÅa-zæøå]\+\>',
      \}

" }}}1

" vim: fdm=marker sw=2
