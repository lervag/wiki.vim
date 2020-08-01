" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#get() abort " {{{1
  for l:matcher in wiki#link#get_matchers_all()
    let l:link = s:matchstr_at_cursor(l:matcher.rx)
    if !empty(l:link)
      " Get link text
      let l:match = s:matchstrpos(l:link.full, get(l:matcher, 'rx_text', ''))
      let l:link.text = l:match[0]
      if !empty(l:link.text)
        let l:link.text_c1 = l:link.c1 + l:match[1]
        let l:link.text_c2 = l:link.c1 + l:match[2] - 1
      endif

      " Get link url position (if available)
      if has_key(l:matcher, 'rx_url')
        let l:match = s:matchstrpos(l:link.full, l:matcher.rx_url)
        if !empty(l:match[0])
          let l:link.url_c1 = l:link.c1 + l:match[1]
          let l:link.url_c2 = l:link.c1 + l:match[2] - 1
        endif
      endif

      let l:link.type = l:matcher.type
      let l:link.toggle = function('wiki#link#template_' . l:matcher.toggle)
      return l:matcher.parser(l:link)
    endif
  endfor

  return {}
endfunction

" }}}1
function! wiki#link#get_all(...) abort "{{{1
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

      " Create link
      let l:link = {}
      let l:link.full = matchstr(l:line, wiki#rx#link(), l:col)
      let l:link.lnum = l:lnum
      let l:link.c1 = l:c1
      let l:link.c2 = l:c1 + strlen(l:link.full)
      let l:col = l:link.c2

      " Match link to type and add details
      for l:matcher in wiki#link#get_matchers_links()
        if l:matcher.type ==# 'ref' | continue | endif
        if l:link.full =~# substitute(l:matcher.rx, '^^\?', '^', '')
          let l:link.text = matchstr(l:link.full, get(l:matcher, 'rx_text', ''))
          let l:link.type = l:matcher.type
          let l:link.toggle = function('wiki#link#template_' . l:matcher.toggle)
          call add(l:links, l:matcher.parser(l:link, { 'origin' : l:file }))
          break
        endif
      endfor
    endwhile
  endfor

  return l:links
endfunction

"}}}1
function! wiki#link#get_at_pos(line, col) abort " {{{1
  let l:save_pos = getcurpos()
  call setpos('.', [0, a:line, a:col, 0])

  let l:link = wiki#link#get()

  call setpos('.', l:save_pos)
  return l:link
endfunction

" }}}1

function! wiki#link#show(...) abort "{{{1
  let l:link = wiki#link#get()

  echohl Title
  echo 'wiki.vim: '
  echohl NONE
  if empty(l:link) || l:link.type ==# 'word'
    echon 'No link detected'
  else
    echon 'Link type/scheme = ' l:link.type '/' l:link.scheme
    if !empty(l:link.text)
      echohl ModeMsg
      echo 'Text: '
      echohl NONE
      echon l:link.text
    endif
    echohl ModeMsg
    echo 'URL: '
    echohl NONE
    echon l:link.url
  endif
  echohl NONE
endfunction

" }}}1
function! wiki#link#open(...) abort "{{{1
  let l:link = wiki#link#get()

  try
    if has_key(l:link, 'open')
      if g:wiki_write_on_nav | update | endif
      call call(l:link.open, a:000, l:link)
    else
      call wiki#link#toggle(l:link)
    endif
  catch /E37:/
    echoerr 'E37: Can''t open link before you''ve saved the current buffer.'
  endtry
endfunction

" }}}1
function! wiki#link#toggle(...) abort " {{{1
  let l:link = a:0 > 0 ? a:1 : wiki#link#get()
  if empty(l:link) | return | endif

  " Use stripped url for wiki links
  let l:url = get(l:link, 'scheme', '') ==# 'wiki'
        \ ? l:link.stripped
        \ : get(l:link, 'url', '')
  if empty(l:url) | return | endif

  " Apply link template from toggle
  let l:new = l:link.toggle(l:url, l:link.text)

  " Replace link in text
  let l:line = getline(l:link.lnum)
  call setline(l:link.lnum,
        \ strpart(l:line, 0, l:link.c1-1) . l:new . strpart(l:line, l:link.c2))
endfunction

" }}}1
function! wiki#link#toggle_visual() abort " {{{1
  normal! gv"wy

  let l:link = {
        \ 'url' : wiki#u#trim(getreg('w')),
        \ 'text' : '',
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : s:handle_multibyte(getpos("'>")[2]),
        \ 'toggle' : function('wiki#link#template_word'),
        \}

  if !empty(b:wiki.link_extension)
    let l:link.text = l:link.url
    let l:link.url .= b:wiki.link_extension
  endif

  call wiki#link#toggle(l:link)
endfunction

" }}}1
function! wiki#link#toggle_operator(type) abort " {{{1
  let l:save = @@
  silent execute 'normal! `[v`]y'
  let l:word = substitute(@@, '\s\+$', '', '')
  let l:diff = strlen(@@) - strlen(l:word)
  let @@ = l:save

  let l:link = {
        \ 'url' : l:word,
        \ 'text' : '',
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : getpos("'>")[2] - l:diff,
        \ 'toggle' : function('wiki#link#template_word'),
        \}

  if !empty(b:wiki.link_extension)
    let l:link.text = l:link.url
    let l:link.url .= b:wiki.link_extension
  endif

  let s:operator = 1
  call wiki#link#toggle(l:link)
  unlet! s:operator
endfunction

" }}}1


function! s:matchstr_at_cursor(regex) abort " {{{1
  let l:lnum = line('.')

  " Seach backwards for current regex
  let l:c1 = searchpos(a:regex, 'ncb',  l:lnum)[1]
  if l:c1 == 0 | return {} | endif

  " Ensure that the cursor is positioned on top of the match
  let l:c1e = searchpos(a:regex, 'ncbe', l:lnum)[1]
  if l:c1e >= l:c1 && l:c1e < col('.') | return {} | endif

  " Find the end of the match
  let l:c2 = searchpos(a:regex, 'nce',  l:lnum)[1]
  if l:c2 == 0 | return {} | endif

  let l:c2 = s:handle_multibyte(l:c2)

  return {
        \ 'full' : strpart(getline('.'), l:c1-1, l:c2-l:c1+1),
        \ 'lnum' : l:lnum,
        \ 'c1' : l:c1,
        \ 'c2' : l:c2,
        \}
endfunction

"}}}1
function! s:matchstrpos(...) abort " {{{1
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

" }}}1
function! s:handle_multibyte(cnum) abort " {{{1
  if a:cnum <= 0 | return a:cnum | endif
  let l:bytes = len(strcharpart(getline('.')[a:cnum-1:], 0, 1))
  return a:cnum + l:bytes - 1
endfunction

" }}}1

"
" Templates translate url and possibly text into an appropriate link
"
function! wiki#link#template_wiki(url, ...) abort " {{{1
  let l:text = a:0 > 0 && !empty(a:1)
        \ ? a:1 ==# a:url[1:] ? '' : a:1
        \ : ''

  if l:text ==# a:url
    let l:text = ''
  endif

  return empty(l:text)
        \ ? '[[' . a:url . ']]'
        \ : '[[' . a:url . '|' . l:text . ']]'
endfunction

" }}}1
function! wiki#link#template_md(url, ...) abort " {{{1
  let l:text = a:0 > 0 ? a:1 : ''
  return '[' . (empty(l:text) ? a:url : l:text) . '](' . a:url . ')'
endfunction

" }}}1
function! wiki#link#template(...) abort " {{{1
  "
  " Pick the relevant link template command to use based on the users
  " settings. Default to the wiki style one if its not set.
  "
  try
    return call('wiki#link#template_' . g:wiki_link_target_type, a:000)
  catch /E117:/
      echoerr 'Link target type does not exist: ' . l:type
      echoerr 'See ":help g:wiki_link_target_type" for help'
  endtry
endfunction

" }}}1
function! wiki#link#template_word(url, ...) abort " {{{1
  "
  " This template returns a wiki template for the provided word(s). It does
  " a smart search for likely candidates and if there is no unique match, it
  " asks for target link.
  "
  let l:text = a:0 > 0 ? a:1 : ''
  let l:url = a:url

  "
  " Allow to map text -> url
  "
  if !empty(g:wiki_map_link_create) && exists('*' . g:wiki_map_link_create)
    let l:url = call(g:wiki_map_link_create, [a:url])
  endif

  if empty(l:text)
    let l:text = a:url
  endif

  "
  " First try local page
  "
  if filereadable(printf('%s/%s.%s', expand('%:p:h'), l:url, b:wiki.extension))
    return wiki#link#template(l:url, l:text)
  endif

  "
  " Next try at wiki root
  "
  if filereadable(printf('%s/%s.%s', b:wiki.root, l:url, b:wiki.extension))
    return wiki#link#template('/' . l:url, l:text)
  endif

  "
  " Finally we see if there are completable candidates
  "
  let l:candidates = map(
        \ glob(printf('%s/%s*.%s', b:wiki.root, l:url, b:wiki.extension), 0, 1),
        \ 'fnamemodify(v:val, '':t:r'')')

  "
  " Solve trivial cases first
  "
  if len(l:candidates) == 0
    return wiki#link#template((b:wiki.in_journal ? '/' : '') . l:url, l:text)
  elseif len(l:candidates) == 1
    return wiki#link#template('/' . l:candidates[0])
  endif

  " Create menu
  let l:list_menu = []
  for l:i in range(len(l:candidates))
    let l:list_menu += [['[' . (l:i + 1) . '] ', l:candidates[l:i]]]
  endfor
  let l:list_menu += [['[n] ', 'New page at wiki root']]
  let l:list_menu += [['[x] ', 'Abort']]

  "
  " Finally we ask for user input to choose desired candidate
  "
  while 1
    redraw

    " Print the menu; fancy printing is not possible with operator mapping
    if exists('s:operator')
      echo join(map(copy(l:list_menu), 'v:val[0] . v:val[1]'), "\n")
    else
      for [l:key, l:val] in l:list_menu
        echohl ModeMsg
        echo l:key
        echohl NONE
        echon l:val
      endfor
    endif

    let l:choice = nr2char(getchar())
    if l:choice ==# 'x'
      redraw!
      return l:url
    endif

    if l:choice ==# 'n'
      redraw!
      return wiki#link#template(l:url, l:text)
    endif

    if str2nr(l:choice) > 0
      try
        let l:cand = l:candidates[l:choice - 1]
        redraw!
        return wiki#link#template('/' . l:cand)
      catch
        continue
      endtry
    endif
  endwhile
endfunction

" }}}1
function! wiki#link#template_ref(...) dict abort " {{{1
  let l:text = self.id
  let l:url = self.url
  return wiki#link#template_md(l:url, l:text)
endfunction

" }}}1
function! wiki#link#template_ref_target(url, ...) abort " {{{1
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
function! wiki#link#get_matcher(name) abort " {{{1
  return s:matcher_{a:name}
endfunction

" }}}1
function! wiki#link#get_matcher_opt(name, opt) abort " {{{1
  return escape(s:matcher_{a:name}[a:opt], '')
endfunction

" }}}1
function! wiki#link#get_matchers_all() abort " {{{1
  return [
        \ s:matcher_wiki,
        \ s:matcher_md,
        \ s:matcher_ref_target,
        \ s:matcher_ref_single,
        \ s:matcher_ref_double,
        \ s:matcher_url,
        \ s:matcher_shortcite,
        \ s:matcher_date,
        \ s:matcher_word,
        \]
endfunction

" }}}1
function! wiki#link#get_matchers_links() abort " {{{1
  return [
        \ s:matcher_wiki,
        \ s:matcher_md,
        \ s:matcher_ref_target,
        \ s:matcher_ref_single,
        \ s:matcher_ref_double,
        \ s:matcher_url,
        \ s:matcher_shortcite,
        \]
endfunction

" }}}1

"
" Parsers create a proper link of a given type based on general input
"
function! s:parser_general(link, ...) abort dict " {{{1
  return extend(a:link, call('wiki#url#parse',
        \ [matchstr(a:link.full, get(self, 'rx_url', get(self, 'rx')))]
        \ + a:000))
endfunction

" }}}1
function! s:parser_date(link, ...) abort dict " {{{1
  return extend(a:link, call('wiki#url#parse',
        \ ['journal:' . a:link.full] + a:000))
endfunction

" }}}1
function! s:parser_word(link, ...) abort dict " {{{1
  if !empty(b:wiki.link_extension)
    let a:link.text = a:link.full
  endif
  return extend(a:link, {
        \ 'scheme' : '',
        \ 'url' : a:link.full . get(b:wiki, 'link_extension', ''),
        \})
endfunction

" }}}1
function! s:parser_ref(link, ...) abort dict " {{{1
  let a:link.id = matchstr(a:link.full, self.rx_target)
  let a:link.lnum_target = searchpos('^\[' . a:link.id . '\]: ', 'nW')[0]
  if a:link.lnum_target == 0 | return a:link | endif

  let a:link.url = matchstr(getline(a:link.lnum_target), s:rx_url)
  if !empty(a:link.url)
    return extend(a:link, call('wiki#url#parse', [a:link.url] + a:000))
  endif

  " The url is not recognized, so we fall back to a link to the reference
  " position.
  function! a:link.open(...) abort dict
    normal! m'
    call cursor(self.lnum_target, 1)
  endfunction

  return a:link
endfunction

" }}}1
function! s:parser_shortcite(link, ...) abort dict " {{{1
  return extend(a:link, call('wiki#url#parse',
        \ ['zot:' . strpart(a:link.full, 1)] + a:000))
endfunction

" }}}1

" Common url regex
let s:rx_url = '\<\l\+:\%(\/\/\)\?[^ \t()\[\]|]\+'
let s:rx_reftext = '[^\\\[\]]\{-}'
let s:rx_reftarget = '\%(\d\+\|\a[-_. [:alnum:]]\+\)'

"
" These are the actual matchers. Link matchers are the matcher objects used to
" detect, parse, and create link objects.
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
" {{{1 s:matcher_ref_single
let s:matcher_ref_single = {
      \ 'type' : 'ref',
      \ 'parser' : function('s:parser_ref'),
      \ 'toggle' : 'ref',
      \ 'rx' : '[\]\[]\@<!'
      \   . '\[' . s:rx_reftarget . '\]'
      \   . '[\]\[]\@!',
      \ 'rx_target' : '\[\zs' . s:rx_reftarget . '\ze\]',
      \}

" }}}1
" {{{1 s:matcher_ref_double
let s:matcher_ref_double = {
      \ 'type' : 'ref',
      \ 'parser' : function('s:parser_ref'),
      \ 'toggle' : 'ref',
      \ 'rx' : '[\]\[]\@<!'
      \   . '\[' . s:rx_reftext   . '\]'
      \   . '\[' . s:rx_reftarget . '\]'
      \   . '[\]\[]\@!',
      \ 'rx_target' :
      \     '\['    . s:rx_reftext   . '\]'
      \   . '\[\zs' . s:rx_reftarget . '\ze\]',
      \ 'rx_text' :
      \     '\[\zs' . s:rx_reftext   . '\ze\]'
      \   . '\['    . s:rx_reftarget . '\]'
      \}

" }}}1
" {{{1 s:matcher_ref_target
let s:matcher_ref_target = {
      \ 'type' : 'ref_target',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'ref_target',
      \ 'rx' : '^\s*\[' . s:rx_reftarget . '\]:\s\+' . s:rx_url,
      \ 'rx_url' : '\[' . s:rx_reftarget . '\]:\s\+\zs' . s:rx_url,
      \ 'rx_text' : '^\s*\[\zs' . s:rx_reftarget . '\ze\]',
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
" {{{1 s:matcher_shortcite
let s:matcher_shortcite = {
      \ 'type' : 'url',
      \ 'parser' : function('s:parser_shortcite'),
      \ 'toggle' : 'md',
      \ 'rx'     : '\%(\s\|^\|\[\)\zs@[-_a-zA-Z0-9]\+\>',
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
      \ 'rx' : wiki#rx#word,
      \}

" }}}1
