" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#get() abort " {{{1
  if wiki#u#is_code() | return {} | endif

  for l:link_definition in g:wiki#link#def#all
    let l:match = s:match_at_cursor(l:link_definition.rx)
    if empty(l:match) | continue | endif

    return wiki#link#class#new(l:link_definition, l:match)
  endfor

  return {}
endfunction

function! s:match_at_cursor(regex) abort " {{{2
  let l:lnum = line('.')

  " Seach backwards for current regex
  let l:c1 = searchpos(a:regex, 'ncb', l:lnum)[1]
  if l:c1 == 0 | return {} | endif

  " Ensure that the cursor is positioned on top of the match
  let l:c1e = searchpos(a:regex, 'ncbe', l:lnum)[1]
  if l:c1e >= l:c1 && l:c1e < col('.') | return {} | endif

  " Find the end of the match
  let l:c2 = searchpos(a:regex, 'nce', l:lnum)[1]
  if l:c2 == 0 | return {} | endif

  let l:c2 = wiki#u#cnum_to_byte(l:c2)

  return {
        \ 'content': strpart(getline('.'), l:c1-1, l:c2-l:c1+1),
        \ 'filename': expand('%:p'),
        \ 'pos_end': [l:lnum, l:c2],
        \ 'pos_start': [l:lnum, l:c1],
        \}
endfunction

"}}}2

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

      let l:content = matchstr(l:line, g:wiki#rx#link, l:c2)
      let l:c2 = l:c1 + strlen(l:content)

      for l:link_definition in g:wiki#link#def#all_real
        if l:content =~# l:link_definition.rx
          call add(l:links, wiki#link#class#new(l:link_definition, {
                \ 'content': l:content,
                \ 'filename': l:file,
                \ 'pos_start': [l:lnum, l:c1],
                \ 'pos_end': [l:lnum, l:c2],
                \}))
          break
        endif
      endfor
    endwhile
  endfor

  return l:links
endfunction

"}}}1

function! wiki#link#get_creator(...) abort " {{{1
  let l:ft = expand('%:e')
  if empty(l:ft) || index(g:wiki_filetypes, l:ft) < 0
    let l:ft = g:wiki_filetypes[0]
  endif
  let l:c = get(g:wiki_link_creation, l:ft, g:wiki_link_creation._)

  return a:0 > 0 ? l:c[a:1] : l:c
endfunction

" }}}1
function! wiki#link#get_scheme(link_type) abort " {{{1
  let l:scheme = get(g:wiki_link_default_schemes, a:link_type, '')

  if type(l:scheme) == v:t_dict
    let l:scheme = get(l:scheme, expand('%:e'), '')
  endif

  return l:scheme
endfunction

" }}}1

function! wiki#link#show(...) abort "{{{1
  let l:link = wiki#link#get()

  if empty(l:link) || l:link.type ==# 'word'
    call wiki#log#info('No link detected')
  else
    let l:viewer = {
          \ 'name': 'WikiLinkInfo',
          \ 'items': l:link.describe()
          \}
    function! l:viewer.print_content() abort dict
      for [l:key, l:value] in self.items
        call append('$', printf(' %-14s %s', l:key, l:value))
      endfor
    endfunction

    call wiki#scratch#new(l:viewer)
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
    elseif g:wiki_link_transform_on_follow
      call l:link.transform()
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
    let l:new = wiki#link#template#{l:link.type}(l:link.url, l:title, l:link)
  catch /E117:/
    let l:new = wiki#link#template#wiki(l:link.url, l:title)
  endtry

  call l:link.replace(l:new)
endfunction

" }}}1
function! wiki#link#transform_current() abort " {{{1
  let l:link = wiki#link#get()
  if empty(l:link) | return | endif

  call l:link.transform()
endfunction

" }}}1
function! wiki#link#transform_visual() abort " {{{1
  normal! gv"wy

  let l:lnum = line('.')
  let l:c1 = getpos("'<")[2]
  let l:c2 = wiki#u#cnum_to_byte(getpos("'>")[2])
  let l:link = wiki#link#class#new(g:wiki#link#def#word, {
        \ 'content': wiki#u#trim(getreg('w')),
        \ 'filename': expand('%:p'),
        \ 'pos_start': [l:lnum, l:c1],
        \ 'pos_end': [l:lnum, l:c2],
        \})

  call l:link.transform()
endfunction

" }}}1
function! wiki#link#transform_operator(type) abort " {{{1
  let l:save = @@
  silent execute 'normal! `[v`]y'
  let l:word = substitute(@@, '\s\+$', '', '')
  let l:diff = strlen(@@) - strlen(l:word)
  let @@ = l:save

  let l:lnum = line('.')
  let l:c1 = getpos("'<")[2]
  let l:c2 = getpos("'>")[2] - l:diff
  let l:link = wiki#link#class#new(g:wiki#link#def#word, {
        \ 'content': l:word,
        \ 'filename': expand('%:p'),
        \ 'pos_start': [l:lnum, l:c1],
        \ 'pos_end': [l:lnum, l:c2],
        \})

  let g:wiki#ui#buffered = v:true
  call l:link.transform()
  let g:wiki#ui#buffered = v:false
endfunction

" }}}1

function! wiki#link#template(url, text) abort " {{{1
  " Pick the relevant link template command to use based on the users
  " settings. Default to the wiki style one if its not set.

  try
    let l:type = wiki#link#get_creator('link_type')
    return wiki#link#template#{l:type}(a:url, a:text)
  catch /E117:/
    call wiki#log#warn(
          \ 'Target link type does not exist: ' . l:type,
          \ 'See ":help g:wiki_link_creation" for help'
          \)
  endtry
endfunction

" }}}1
