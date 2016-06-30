" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#page#delete() "{{{1
  let l:input_response = input('Delete "' . expand('%') . '" [y]es/[N]o? ')
  if l:input_response !~? '^y' | return | endif

  let l:filename = expand('%:p')
  try
    call delete(l:filename)
  catch /.*/
    echomsg 'Vimwiki Error: Cannot delete "' . expand('%:t:r') . '"!'
    return
  endtry

  call vimwiki#nav#return()
  execute 'bdelete! ' . escape(l:filename, " ")
endfunction

"}}}1
function! vimwiki#page#rename() "{{{1
  " Check if current file exists
  if !filereadable(expand('%:p'))
    echom 'Vimwiki Error: Cannot rename "' . expand('%:p')
          \ . '". It does not exist! (New file? Save it before renaming.)'
    return
  endif

  if b:vimwiki.in_diary
    echom 'Not supported yet.'
    return
  endif

  " Ask if user wants to rename
  if input('Rename "' . expand('%:t:r') . '" [y]es/[N]o? ') !~? '^y'
    return
  endif

  " Get new page name
  let l:new = {}
  let l:new.name = substitute(input('Enter new name: '), '\.wiki$', '', '')
  echon "\r"
  if empty(substitute(l:new.name, '\s*', '', ''))
    echom 'Vimwiki Error: Cannot rename to an empty filename!'
    return
  endif

  " Expand to full path name, check if already exists
  let l:new.path = expand('%:p:h') . '/' . l:new.name . '.wiki'
  if filereadable(l:new.path)
    echom 'Vimwiki Error: Cannot rename to "' . l:new.path
          \ . '". File with that name exist!'
    return
  endif

  " Rename current file to l:new.path
  try
    echom 'Vimwiki: Renaming ' . expand('%:t')
          \ . ' to ' . fnamemodify(l:new.path, ':t')
    if rename(expand('%:p'), l:new.path) != 0
      throw 'Cannot rename!'
    end
    setlocal buftype=nofile
  catch
    echom 'Vimwiki Error: Cannot rename "'
          \ . expand('%:t:r') . '" to "' . l:new.path . '"!'
    return
  endtry

  " Store some info from old buffer
  let l:old = {
        \ 'path' : expand('%:p'),
        \ 'name' : expand('%:t:r'),
        \ 'prev_link' : get(b:, 'vimwiki_prev_link', ''),
        \}

  " Get list of open wiki buffers
  let l:bufs = map(filter(map(filter(range(1, bufnr('$')),
        \       'bufexists(v:val)'),
        \     'fnamemodify(bufname(v:val), '':p'')'),
        \   'v:val =~# ''.wiki$'''),
        \ '[v:val, getbufvar(v:val, ''vimwiki.prev_link'')]')

  " Save and close wiki buffers
  for [l:bufname, l:dummy] in l:bufs
    execute 'b' fnameescape(l:bufname)
    update
    execute 'bwipeout' fnameescape(l:bufname)
  endfor

  " Update links
  call s:rename_update_links(l:old.name, l:new.name)

  " Restore wiki buffers
  for [l:bufname, l:prev_link] in l:bufs
    if resolve(l:bufname) ==# resolve(l:old.path)
      call s:rename_open_buffer(l:new.path, l:old.prev_link)
    else
      call s:rename_open_buffer(l:bufname, l:prev_link)
    endif
  endfor
endfunction

" }}}1
function! vimwiki#page#get_links(...) "{{{1
  let l:file = a:0 > 0 ? a:1 : expand('%')
  if !filereadable(l:file) | return [] | endif

  " TODO: Should match more types of links
  let l:regex = g:vimwiki.link_matcher.wiki.rx_url

  let l:links = []
  let l:lnum = 0
  for l:line in readfile(l:file)
    let l:lnum += 1
    let l:count = 0
    while 1
      let l:count += 1
      let l:col = match(l:line, l:regex, 0, l:count)+1
      if l:col <= 0 | break | endif

      let l:link = extend(
            \ vimwiki#link#parse(
            \   matchstr(l:line, l:regex, 0, l:count),
            \   { 'origin' : l:file }),
            \ { 'lnum' : l:lnum, 'col' : l:col })

      if has_key(l:link, 'filename')
        call add(l:links, l:link)
      endif
    endwhile
  endfor

  return l:links
endfunction

"}}}1

function! s:rename_open_buffer(fname, prev_link) " {{{1
  let l:opts = {}
  if !empty(a:prev_link)
    let l:opts.prev_link = a:prev_link
  endif

  silent! call vimwiki#edit_file(a:fname, l:opts)
endfunction

" }}}1
function! s:rename_update_links(old, new) " {{{1
  let l:pattern  = '\v\[\[\/?\zs' . a:old . '\ze%(#.*)?%(|.*)?\]\]'
  let l:pattern .= '|\[.*\]\[\zs' . a:old . '\ze%(#.*)?\]'
  let l:pattern .= '|\[.*\]\(\zs' . a:old . '\ze%(#.*)?\)'
  let l:pattern .= '|\[\zs' . a:old . '\ze%(#.*)?\]\[\]'

  for l:file in glob(g:vimwiki.root . '**/*.wiki', 0, 1)
    let l:updates = 0
    let l:lines = []
    for l:line in readfile(l:file)
      if match(l:line, l:pattern) != -1
        let l:updates = 1
        call add(l:lines, substitute(l:line, l:pattern, a:new, 'g'))
      else
        call add(l:lines, l:line)
      endif
    endfor

    if l:updates
      echom 'Updating links in: ' . fnamemodify(l:file, ':t')
      call rename(l:file, l:file . '#tmp')
      call writefile(l:lines, l:file)
      call delete(l:file . '#tmp')
    endif
  endfor
endfunction

" }}}1

function! vimwiki#page#create_toc() " {{{1
  "
  " Collect new headers
  "
  let l:inside_pre = 0
  let headers = []
  let headers_levels = [['', 0], ['', 0], ['', 0], ['', 0], ['', 0], ['', 0]]
  for l:line in getline(1, '$')
    if l:inside_pre
      if l:line =~# g:vimwiki.rx.preEnd
        let l:inside_pre = 0
      endif
      continue
    endif
    if l:line =~# g:vimwiki.rx.preStart
      let l:inside_pre = 1
      continue
    endif
    if l:line !~# g:vimwiki.rx.header
      continue
    endif

    let h_level = len(matchstr(l:line, '#*'))
    let h_text = vimwiki#u#trim(matchstr(l:line, g:vimwiki.rx.header))

    " Don't include the TOC's header itself
    if h_text ==# 'Innhald'
      continue
    endif
    let headers_levels[h_level-1] = [h_text, headers_levels[h_level-1][1]+1]
    for idx in range(h_level, 5) | let headers_levels[idx] = ['', 0] | endfor

    let h_complete_id = ''
    for l in range(h_level-1)
      if headers_levels[l][0] != ''
        let h_complete_id .= headers_levels[l][0].'#'
      endif
    endfor
    let h_complete_id .= headers_levels[h_level-1][0]

    call add(headers, [h_level, h_complete_id, h_text])
  endfor

  let lines = []
  let startindent = repeat(' ', shiftwidth())
  let indentstring = repeat(' ', shiftwidth())
  let bullet = vimwiki#lst#default_symbol().' '
  for [lvl, link, desc] in headers
    let esc_link = substitute(link, "'", "''", 'g')
    let esc_desc = substitute(desc, "'", "''", 'g')
    let link = substitute(g:vimwiki.link_matcher.wiki.template[1], '__Url__',
          \ '\='."'".'#'.esc_link."'", '')
    let link = substitute(link, '__Text__', '\='."'".esc_desc."'", '')
    call add(lines, startindent.repeat(indentstring, lvl-1).bullet.link)
  endfor

  let links_rx = '\m^\s*'.vimwiki#u#escape(vimwiki#lst#default_symbol()).' '

  call s:update_listing_in_buffer(lines, 'Innhald', links_rx, 1, 1)
endfunction

" }}}1
function! s:update_listing_in_buffer(strings, start_header, content_regex, default_lnum, create) " {{{1
  " check if the listing is already there
  let already_there = 0

  let header_rx = '\m^\s*# ' . a:start_header

  let start_lnum = 1
  while start_lnum <= line('$')
    if getline(start_lnum) =~# header_rx
      let already_there = 1
      break
    endif
    let start_lnum += 1
  endwhile

  if !already_there && !a:create
    return
  endif

  let winview_save = winsaveview()
  let cursor_line = winview_save.lnum
  let is_cursor_after_listing = 0

  let is_fold_closed = 1

  let lines_diff = 0

  if already_there
    let is_fold_closed = ( foldclosed(start_lnum) > -1 )
    " delete the old listing
    let whitespaces_in_first_line = matchstr(getline(start_lnum), '\m^\s*')
    let end_lnum = start_lnum + 1
    while end_lnum <= line('$') && getline(end_lnum) =~# a:content_regex
      let end_lnum += 1
    endwhile
    let is_cursor_after_listing = ( cursor_line >= end_lnum )
    " We'll be removing a range.  But, apparently, if folds are enabled, Vim
    " won't let you remove a range that overlaps with closed fold -- the entire
    " fold gets deleted.  So we temporarily disable folds, and then reenable
    " them right back.
    let foldenable_save = &l:foldenable
    setlo nofoldenable
    silent exe start_lnum.','.string(end_lnum - 1).'delete _'
    let &l:foldenable = foldenable_save
    let lines_diff = 0 - (end_lnum - start_lnum)
  else
    let start_lnum = a:default_lnum
    let is_cursor_after_listing = ( cursor_line > a:default_lnum )
    let whitespaces_in_first_line = ''
  endif

  let start_of_listing = start_lnum

  " write new listing
  let new_header = whitespaces_in_first_line
        \ . substitute(g:vimwiki.rx.H1_Template,
        \ '__Header__', '\='."'".a:start_header."'", '')
  call append(start_lnum - 1, new_header)
  let start_lnum += 1
  let lines_diff += 1 + len(a:strings)
  for string in a:strings
    call append(start_lnum - 1, string)
    let start_lnum += 1
  endfor
  " append an empty line if there is not one
  if start_lnum <= line('$') && getline(start_lnum) !~# '\m^\s*$'
    call append(start_lnum - 1, '')
    let lines_diff += 1
  endif

  " Open fold, if needed
  if !is_fold_closed && ( foldclosed(start_of_listing) > -1 )
    exe start_of_listing
    norm! zo
  endif

  if is_cursor_after_listing
    let winview_save.lnum += lines_diff
  endif
  call winrestview(winview_save)
endfunction

" }}}1

" vim: fdm=marker sw=2

