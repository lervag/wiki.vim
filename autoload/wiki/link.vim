" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#get() abort " {{{1
  if wiki#u#is_code() | return {} | endif

  for l:matcher in s:matchers
    let l:link = l:matcher.match_at_cursor()
    if !empty(l:link) | return l:link | endif
  endfor

  return {}
endfunction

" }}}1
function! wiki#link#get_at_pos(line, col) abort " {{{1
  let l:save_pos = getcurpos()
  call setpos('.', [0, a:line, a:col, 0])

  let l:link = wiki#link#get()

  call setpos('.', l:save_pos)
  return l:link
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
    while v:true
      let l:c1 = match(l:line, g:wiki#rx#link, l:col) + 1
      if l:c1 == 0 | break | endif

      let l:match = {}
      let l:match.full = matchstr(l:line, g:wiki#rx#link, l:col)
      let l:match.filename = l:file
      let l:match.lnum = l:lnum
      let l:match.c1 = l:c1
      let l:match.c2 = l:c1 + strlen(l:match.full)
      let l:match.origin = l:file
      let l:col = l:match.c2

      " Match link to type and add details
      for l:matcher in s:matchers_real
        if l:match.full =~# l:matcher.rx
          call add(l:links, l:matcher.create_link(l:match))
          break
        endif
      endfor
    endwhile
  endfor

  return l:links
endfunction

"}}}1

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
function! wiki#link#follow(...) abort "{{{1
  let l:link = wiki#link#get()

  try
    if has_key(l:link, 'follow')
      if g:wiki_write_on_nav | update | endif
      call call(l:link.follow, a:000, l:link)
    elseif g:wiki_link_toggle_on_follow
      call wiki#link#toggle(l:link)
    endif
  catch /E37:/
    call wiki#log#error(
          \ "Can't follow link before you've saved the current buffer.")
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
        \ 'filename': expand('%:p'),
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : wiki#u#cnum_to_byte(getpos("'>")[2]),
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
        \ 'filename': expand('%:p'),
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


" {{{1 Initialize matchers

let s:matchers = [
      \ wiki#link#wiki#matcher(),
      \ wiki#link#adoc_xref_bracket#matcher(),
      \ wiki#link#adoc_xref_inline#matcher(),
      \ wiki#link#adoc_link#matcher(),
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

let s:matchers_real = [
      \ wiki#link#wiki#matcher(),
      \ wiki#link#adoc_xref_bracket#matcher(),
      \ wiki#link#adoc_xref_inline#matcher(),
      \ wiki#link#adoc_link#matcher(),
      \ wiki#link#md_fig#matcher(),
      \ wiki#link#md#matcher(),
      \ wiki#link#ref_target#matcher(),
      \ wiki#link#url#matcher(),
      \ wiki#link#shortcite#matcher(),
      \]

" }}}1
