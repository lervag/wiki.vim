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
    let l:c2 = 0
    while v:true
      let l:c1 = match(l:line, g:wiki#rx#link, l:c2) + 1
      if l:c1 == 0 | break | endif

      let l:match = {}
      let l:match.content = matchstr(l:line, g:wiki#rx#link, l:c2)
      let l:match.filename = l:file

      let l:c2 = l:c1 + strlen(l:match.content)
      let l:match.pos_start = [l:lnum, l:c1]
      let l:match.pos_end = [l:lnum, l:c2]

      " Match link to type and add details
      for l:matcher in s:matchers_real
        if l:match.content =~# l:matcher.rx
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
    call wiki#log#info('Link info', l:link.pprint())
  endif
endfunction

" }}}1
function! wiki#link#follow(...) abort "{{{1
  let l:link = wiki#link#get()
  if empty(l:link) | return | endif

  try
    if has_key(l:link, 'follow')
      if g:wiki_write_on_nav | update | endif
      call call(l:link.follow, a:000, l:link)
    elseif g:wiki_link_toggle_on_follow
      call l:link.toggle()
    endif
  catch /E37:/
    call wiki#log#error(
          \ "Can't follow link before you've saved the current buffer.")
  endtry
endfunction

" }}}1
function! wiki#link#set_text_from_header() abort "{{{1
  let l:link = wiki#link#get()
  if index(['wiki', 'journal'], l:link.scheme) < 0 | return | endif

  let l:title = wiki#toc#get_page_title(l:link)
  if empty(l:title) | return | endif

  try
    let l:new = wiki#link#{l:link.type}#template(l:link.url, l:title)
  catch /E117:/
    let l:new = wiki#link#wiki#template(l:link.url, l:title)
  endtry

  call l:link.replace(l:new)
endfunction

" }}}1
function! wiki#link#toggle_current() abort " {{{1
  let l:link = wiki#link#get()
  if empty(l:link) | return | endif

  call l:link.toggle()
endfunction

" }}}1
function! wiki#link#toggle_visual() abort " {{{1
  normal! gv"wy

  let l:lnum = line('.')
  let l:c1 = getpos("'<")[2]
  let l:c2 = wiki#u#cnum_to_byte(getpos("'>")[2])

  let l:link = wiki#link#word#matcher().create_link({
        \ 'content': wiki#u#trim(getreg('w')),
        \ 'filename': expand('%:p'),
        \ 'pos_start': [l:lnum, l:c1],
        \ 'pos_end': [l:lnum, l:c2],
        \})

  call l:link.toggle()
endfunction

" }}}1
function! wiki#link#toggle_operator(type) abort " {{{1
  let l:save = @@
  silent execute 'normal! `[v`]y'
  let l:word = substitute(@@, '\s\+$', '', '')
  let l:diff = strlen(@@) - strlen(l:word)
  let @@ = l:save

  let l:lnum = line('.')
  let l:c1 = getpos("'<")[2]
  let l:c2 = getpos("'>")[2] - l:diff

  let l:link = wiki#link#word#matcher().create_link({
        \ 'content': l:word,
        \ 'filename': expand('%:p'),
        \ 'pos_start': [l:lnum, l:c1],
        \ 'pos_end': [l:lnum, l:c2],
        \})

  let g:wiki#ui#buffered = v:true
  call l:link.toggle()
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

" The order between wiki, md and org is tricky here! Wiki and org links are the
" same without description (`[[link]]`) but different with description
" (`[[link|description]]` vs `[[link][description]]`). We order them here such
" that toggling never goes org->wiki or wiki-org, which might dead-lock.
" Without a description, toggle cycles as follows:
"     wiki -> md -> org, which looks like wiki.
" With a description, toggle cycles as follows:
"     wiki -> md -> org -> wiki.
let s:matchers = [
      \ wiki#link#wiki#matcher(),
      \ wiki#link#adoc_xref_bracket#matcher(),
      \ wiki#link#adoc_xref_inline#matcher(),
      \ wiki#link#adoc_link#matcher(),
      \ wiki#link#md_fig#matcher(),
      \ wiki#link#md#matcher(),
      \ wiki#link#org#matcher(),
      \ wiki#link#ref_definition#matcher(),
      \ wiki#link#ref_shortcut#matcher(),
      \ wiki#link#ref_collapsed#matcher(),
      \ wiki#link#ref_full#matcher(),
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
      \ wiki#link#org#matcher(),
      \ wiki#link#ref_definition#matcher(),
      \ wiki#link#url#matcher(),
      \ wiki#link#shortcite#matcher(),
      \]

" }}}1
