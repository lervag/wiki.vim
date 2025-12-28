" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#get() abort " {{{1
  if wiki#u#is_code() | return {} | endif

  for l:link_definition in g:wiki#link#definitions#all
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
        \ 'origin': expand('%:p'),
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

function! wiki#link#get_all_from_file(...) abort "{{{1
  let l:file = a:0 > 0 ? a:1 : expand('%:p')
  if !filereadable(l:file) | return [] | endif

  return wiki#link#get_all_from_lines(readfile(l:file), l:file)
endfunction

"}}}1
function! wiki#link#get_all_from_range(line1, line2) abort "{{{1
  let l:lines = getline(a:line1, a:line2)
  return wiki#link#get_all_from_lines(l:lines, expand('%:p'), a:line1)
endfunction

"}}}1
function! wiki#link#get_all_from_lines(lines, file, ...) abort "{{{1
  let l:links = []

  let l:in_code = v:false
  let l:skip = v:false

  let l:lnum = a:0 > 0 ? (a:1 - 1) : 0
  for l:line in a:lines
    let l:lnum += 1

    let [l:in_code, l:skip] = wiki#u#is_code_by_string(l:line, l:in_code)
    if l:skip | continue | endif

    let l:c2 = 0
    while v:true
      let l:c1 = match(l:line, g:wiki#rx#link, l:c2) + 1
      if l:c1 == 0 | break | endif

      let l:content = matchstr(l:line, g:wiki#rx#link, l:c2)
      let l:c2 = l:c1 + strlen(l:content)

      for l:link_definition in g:wiki#link#definitions#all_real
        if l:content =~# l:link_definition.rx
          call add(l:links, wiki#link#class#new(l:link_definition, {
                \ 'content': l:content,
                \ 'origin': a:file,
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

function! wiki#link#add(path, mode, ...) abort " {{{1
  let l:creator = wiki#link#get_creator()

  if a:mode == 'visual'
    let l:at_last_col = getpos("'>")[2] >= col('$') - 1
    normal! gv"wd
    let l:defaults = #{
          \ position: getcurpos()[1:2],
          \ text: trim(getreg('w'))
          \}
  else
    let l:defaults = #{
          \ position: getcurpos()[1:2],
          \ text: has_key(l:creator, 'link_text')
          \   ? l:creator.link_text(a:path)
          \   : a:path
          \}
  endif

  let l:options = extend(l:defaults, a:0 > 0 ? a:1 : {})

  let l:url = a:path
  if has_key(l:creator, 'url_transform')
    let l:transformed = l:creator.url_transform(a:path)
    if !empty(l:transformed)
      let l:url = l:transformed
    endif
  elseif wiki#paths#is_abs(a:path)
    let l:cwd = expand('%:p:h')
    let l:url = stridx(a:path, l:cwd) == 0
          \ ? wiki#paths#to_wiki_url(a:path, l:cwd)
          \ : '/' .. wiki#paths#to_wiki_url(a:path)
  endif

  let l:link_string = wiki#link#template(l:url, l:options.text)

  let l:line = getline(l:options.position[0])
  if a:mode ==# 'insert' && l:options.position[1] == col('$') - 1
    call setline(l:options.position[0], l:line . l:link_string)
  elseif a:mode ==# 'visual' && l:at_last_col
    call setline(l:options.position[0], l:line . l:link_string)
  else
    call setline(l:options.position[0],
          \ strpart(l:line, 0, l:options.position[1]-1)
          \ .. l:link_string
          \ .. strpart(l:line, l:options.position[1]-1))
  endif

  if l:options.position == getcurpos()[1:2]
    call cursor(
          \ l:options.position[0],
          \ l:options.position[1] + len(l:link_string)
          \)
  endif
endfunction

" }}}1
function! wiki#link#remove() abort " {{{1
  let l:link = wiki#link#get()
  if empty(l:link) | return | endif

  call l:link.replace(
        \ empty(l:link.text) ? l:link.url_raw : l:link.text
        \)
endfunction

" }}}1

function! wiki#link#get_creator(...) abort " {{{1
  let l:ft = expand('%:e')
  if empty(l:ft) || index(g:wiki_filetypes, l:ft) < 0
    let l:ft = g:wiki_filetypes[0]
  endif
  let l:c = extend(
        \ get(g:wiki_link_creation, l:ft, {}),
        \ g:wiki_link_creation._, 'keep')

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

function! wiki#link#incoming_hover() abort " {{{1
  let l:links_all = wiki#graph#get_backlinks_enriched()

  let l:lnum = line('.')
  if l:lnum == 1
    call filter(l:links_all, { _, x -> x.target_lnum <= 1 })
  else
    call filter(l:links_all, { _, x -> x.target_lnum == l:lnum })
  endif

  let l:links_per_source = wiki#u#group_by(l:links_all, 'filename_from')
  let l:keys = keys(l:links_per_source)
  let l:sources = map(deepcopy(l:keys), { _, x -> wiki#paths#to_node(x) })
  let l:source_idx = wiki#ui#select(l:sources, #{
          \ prompt: 'Incoming links (select one to go to source):',
          \ return: 'index',
          \ auto_select: v:false,
          \})

  if l:source_idx >= 0
    let l:filename = l:keys[l:source_idx]
    let l:link = l:links_per_source[l:filename][0]
    execute 'edit' fnameescape(l:filename)
    call cursor([l:link.lnum, l:link.col])
    normal! zv
  endif
endfunction

" }}}1
function! wiki#link#incoming_display_toggle() abort " {{{1
  let l:id = nvim_create_namespace("wiki.vim")
  let l:extmarks = nvim_buf_get_extmarks(0, l:id, 0, -1, {})
  if !empty(l:extmarks)
    call nvim_buf_clear_namespace(0, l:id, 0, -1)
  else
    call wiki#link#incoming_display()
  endif
endfunction

" }}}1
function! wiki#link#incoming_display() abort " {{{1
  let l:id = nvim_create_namespace("wiki.vim")
  call nvim_buf_clear_namespace(0, l:id, 0, -1)

  for [l:lnum, l:links_per_line] in items(
        \ wiki#u#group_by(
        \   wiki#graph#get_backlinks_enriched(),
        \   'target_lnum'))

    let l:links_per_source = wiki#u#group_by(l:links_per_line, 'filename_from')
    let l:text = len(l:links_per_source) > 1
          \ ? printf(" from %d sources", len(l:links_per_source))
          \ : printf(" from %s",
          \     wiki#paths#to_node(l:links_per_line[0].filename_from))

    if l:lnum == 0
      call nvim_buf_set_extmark(0, l:id, 0, 0, {
            \ 'virt_text': [[l:text . " ", "DiagnosticVirtualTextWarn"]],
            \ 'virt_text_pos': 'right_align',
            \ 'sign_text': '',
            \ 'sign_hl_group': 'DiagnosticSignWarn',
            \})
    else
      call nvim_buf_set_extmark(0, l:id, l:lnum - 1, 0, {
            \ 'virt_text': [[l:text, "DiagnosticVirtualTextHint"]],
            \ 'sign_text': '',
            \ 'sign_hl_group': 'DiagnosticSignHint',
            \})
    endif
  endfor
endfunction

" }}}1
function! wiki#link#incoming_clear() abort " {{{1
  let l:id = nvim_create_namespace("wiki.vim")
  call nvim_buf_clear_namespace(0, l:id, 0, -1)
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
  let l:edit_cmd = a:0 > 0 ? a:1 : 'edit'
  let l:link = wiki#link#get()
  if empty(l:link) | return | endif

  if l:link.type ==# 'word'
    if g:wiki_link_transform_on_follow
      call l:link.transform()
    endif
    return
  endif

  " Push origin location to navigation stack
  let l:origin = {
        \ 'file': expand('%:p'),
        \ 'cursor': getcurpos(),
        \ 'link': l:link
        \}
  call wiki#nav#add_to_stack(l:origin)

  call wiki#graph#mark_refreshed(l:origin.file)

  try
    call wiki#url#follow(l:link.url, l:edit_cmd)
  catch /E37:/
    call wiki#log#error(
          \ "Can't follow link before you've saved the current buffer.")
  endtry

  " Pop origin from stack if following the link did not change the location
  if l:origin.file ==# expand('%:p')
        \ && l:origin.cursor == getcurpos()
    call wiki#nav#pop_from_stack()
  endif
endfunction

" }}}1
function! wiki#link#set_text_from_header(range, line1, line2) abort "{{{1
  if a:range == 0
    let l:links = [wiki#link#get()]
  else
    let l:links = wiki#link#get_all_from_range(a:line1, a:line2)
  endif

  for l:link in filter(
        \ l:links,
        \ { _, x -> index(['wiki', 'journal', 'md'], x.scheme) >= 0 }
        \)
    let l:title = wiki#toc#get_page_title(l:link)

    if empty(l:title) | return | endif

    try
      let l:new = wiki#link#templates#{l:link.type}(l:link.url_raw, l:title, l:link)
    catch /E117:/
      let l:new = wiki#link#templates#wiki(l:link.url_raw, l:title)
    endtry

    call l:link.replace(l:new)
  endfor
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

  let l:pos1 = getpos("'<")
  let l:pos2 = getpos("'>")
  if l:pos1[1] != l:pos2[1]
    call wiki#log#warn('Cannot create a link from a multi-line selection!')
    return
  endif

  let l:link = wiki#link#class#new(g:wiki#link#definitions#word, {
        \ 'content': trim(getreg('w')),
        \ 'origin': expand('%:p'),
        \ 'pos_start': l:pos1[1:2],
        \ 'pos_end': [l:pos2[1], wiki#u#cnum_to_byte(l:pos2[2])],
        \})

  call l:link.transform()
endfunction

" }}}1
function! wiki#link#transform_operator(type) abort " {{{1
  let l:saved_position = getcurpos()

  let l:save = @@
  silent execute 'normal! `[v`]y'
  let l:word = substitute(@@, '\s\+$', '', '')
  let l:diff = strlen(@@) - strlen(l:word)
  let @@ = l:save

  " Hack: To support multibyte characters at end of the region we move the
  " selection one character to the right, then afterwards we subtract 1 byte.
  silent execute "normal! `[v`]l\<esc>"

  let l:pos1 = getpos("'<")
  let l:pos2 = getpos("'>")
  if l:pos1[1] != l:pos2[1]
    call cursor(l:saved_position[1:])
    call wiki#log#warn('Cannot create a link from a multi-line region!')
    return
  endif

  let l:link = wiki#link#class#new(g:wiki#link#definitions#word, {
        \ 'content': l:word,
        \ 'origin': expand('%:p'),
        \ 'pos_start': l:pos1[1:2],
        \ 'pos_end': [l:pos2[1], l:pos2[2] - 1 - l:diff],
        \})

  call l:link.transform()
endfunction

" }}}1

function! wiki#link#template(url, text) abort " {{{1
  " Pick the relevant link template command to use based on the users
  " settings. Default to the wiki style one if its not set.

  try
    let l:type = wiki#link#get_creator('link_type')
    return wiki#link#templates#{l:type}(a:url, a:text)
  catch /E117:/
    call wiki#log#warn(
          \ 'Target link type does not exist: ' . l:type,
          \ 'See ":help g:wiki_link_creation" for help'
          \)
  endtry
endfunction

" }}}1
