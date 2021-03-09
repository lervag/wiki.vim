" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#get() abort " {{{1
  if wiki#u#is_code() | return {} | endif

  for l:matcher in [
        \ wiki#link#wiki#matcher(),
        \ wiki#link#adoc_xref_bracket#matcher(),
        \ wiki#link#adoc_xref_inline#matcher(),
        \ wiki#link#md_fig#matcher(),
        \ wiki#link#md#matcher(),
        \ wiki#link#ref_target#matcher(),
        \ wiki#link#ref_single#matcher(),
        \ wiki#link#ref_double#matcher(),
        \ wiki#link#url#matcher(),
        \ wiki#link#shortcite#matcher(),
        \ wiki#link#date#matcher(),
        \ wiki#link#word#matcher(),
        \]
    let l:link = s:matchstr_at_cursor(l:matcher.rx)
    if !empty(l:link)
      return s:parse_link(l:matcher, l:link)
    endif
  endfor

  return {}
endfunction

" }}}1
function! wiki#link#get_all(...) abort "{{{1
  let l:file = a:0 > 0 ? a:1 : expand('%')
  if !filereadable(l:file) | return [] | endif

  let l:matchers = [
        \ wiki#link#wiki#matcher(),
        \ wiki#link#adoc_xref_bracket#matcher(),
        \ wiki#link#adoc_xref_inline#matcher(),
        \ wiki#link#md_fig#matcher(),
        \ wiki#link#md#matcher(),
        \ wiki#link#ref_target#matcher(),
        \ wiki#link#ref_single#matcher(),
        \ wiki#link#ref_double#matcher(),
        \ wiki#link#url#matcher(),
        \ wiki#link#shortcite#matcher(),
        \]
  let l:links = []
  let l:lnum = 0
  for l:line in readfile(l:file)
    let l:lnum += 1
    let l:col = 0
    while 1
      let l:c1 = match(l:line, g:wiki#rx#link, l:col) + 1
      if l:c1 == 0 | break | endif

      " Create link
      let l:link = {}
      let l:link.full = matchstr(l:line, g:wiki#rx#link, l:col)
      let l:link.lnum = l:lnum
      let l:link.c1 = l:c1
      let l:link.c2 = l:c1 + strlen(l:link.full)
      let l:link.origin = l:file
      let l:col = l:link.c2

      " Match link to type and add details
      for l:matcher in l:matchers
        if l:matcher.type ==# 'ref' | continue | endif
        if l:link.full =~# substitute(l:matcher.rx, '^^\?', '^', '')
          call add(l:links, s:parse_link(l:matcher, l:link))
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

  if empty(l:link) || l:link.type ==# 'word'
    call wiki#log#info('No link detected')
  else
    call wiki#log#info(
          \ 'Link info',
          \ {
          \   'type': l:link.type,
          \   'scheme': get(l:link, 'scheme', 'NONE'),
          \   'url': l:link.url,
          \   'text': get(l:link, 'text', ''),
          \ }
          \)
  endif
endfunction

" }}}1
function! wiki#link#open(...) abort "{{{1
  let l:link = wiki#link#get()

  try
    if has_key(l:link, 'open')
      if g:wiki_write_on_nav | update | endif
      call call(l:link.open, a:000, l:link)
    elseif g:wiki_link_toggle_on_open
      call wiki#link#toggle(l:link)
    endif
  catch /E37:/
    call wiki#log#error(
          \ "Can't open link before you've saved the current buffer.")
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

  " Apply link template from toggle (abort if empty!)
  let l:new = l:link.toggle(l:url, l:link.text)
  if empty(l:new) | return | endif

  " Replace link in text
  let l:line = getline(l:link.lnum)
  call setline(l:link.lnum,
        \ strpart(l:line, 0, l:link.c1-1) . l:new . strpart(l:line, l:link.c2))
endfunction

" }}}1
function! wiki#link#toggle_visual() abort " {{{1
  normal! gv"wy

  let l:link = {
        \ 'url' : 'N/A',
        \ 'text' : wiki#u#trim(getreg('w')),
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : s:handle_multibyte(getpos("'>")[2]),
        \ 'toggle' : function('wiki#link#word#template'),
        \}

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
        \ 'url' : 'N/A',
        \ 'text' : l:word,
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : getpos("'>")[2] - l:diff,
        \ 'toggle' : function('wiki#link#word#template'),
        \}

  let g:wiki#ui#buffered = v:true
  call wiki#link#toggle(l:link)
  let g:wiki#ui#buffered = v:false
endfunction

" }}}1

function! wiki#link#template(url, text) abort " {{{1
  "
  " Pick the relevant link template command to use based on the users
  " settings. Default to the wiki style one if its not set.
  "
  try
    return wiki#link#{g:wiki_link_target_type}#template(a:url, a:text)
  catch /E117:/
    call wiki#log#warn(
          \ 'Link target type does not exist: ' . g:wiki_link_target_type,
          \ 'See ":help g:wiki_link_target_type" for help'
          \)
  endtry
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
function! s:parse_link(matcher, link) abort " {{{1
  let a:link.type = a:matcher.type
  let a:link.url = a:link.full
  let a:link.text = ''
  if has_key(a:matcher, 'toggle')
    let a:link.toggle = a:matcher.toggle
  else
    let a:link.toggle = function(g:wiki_link_toggles[a:link.type])
  endif

  " Get link text
  if has_key(a:matcher, 'rx_text')
    let [l:text, l:c1, l:c2] = s:matchstrpos(a:link.full, a:matcher.rx_text)
    if !empty(l:text)
      let a:link.text = l:text
      let a:link.text_c1 = a:link.c1 + l:c1
      let a:link.text_c2 = a:link.c1 + l:c2 - 1
    endif
  endif

  " Get link url
  if has_key(a:matcher, 'rx_url')
    let [l:url, l:c1, l:c2] = s:matchstrpos(a:link.full, a:matcher.rx_url)
    if !empty(l:url)
      let a:link.url = l:url
      let a:link.url_c1 = a:link.c1 + l:c1
      let a:link.url_c2 = a:link.c1 + l:c2 - 1
    endif
  endif

  if has_key(a:matcher, 'parse')
    return a:matcher.parse(a:link)
  else
    let l:url = has_key(a:matcher, 'scheme')
          \ ? a:matcher.scheme . ':'
          \ : ''
    let l:url .= a:link.url

    return extend(a:link, wiki#url#parse(l:url,
          \ has_key(a:link, 'origin') ? {'origin': a:link.origin} : {}))
  endif
endfunction

" }}}1
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
