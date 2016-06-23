" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#page#delete() "{{{1
  if input('Delete "' . expand('%') . '" [y]es/[N]o? ') !~? '^y'
        \ | return | endif

  let l:filename = expand('%:p')
  try
    call delete(l:filename)
  catch /.*/
    echomsg 'Vimwiki Error: Cannot delete "' . expand('%:t:r') . '"!'
    return
  endtry

  call vimwiki#link#go_back()
  execute 'bdelete! ' . escape(l:filename, " ")

  " reread buffer => deleted wiki link should appear as non-existent
  if !empty(expand('%:p')) | edit | endif
endfunction

"}}}1
function! vimwiki#page#goto_index() " {{{1
  call vimwiki#todo#edit_file('edit', g:vimwiki_path . '/index.wiki', '')
endfunction

" }}}1
function! vimwiki#page#backlinks() "{{{1
  let l:origin = expand("%:p")
  let l:locs = []

  for l:file in globpath(g:vimwiki_path, '**/*.wiki', 0, 1)
    if resolve(l:file) ==# resolve(l:origin) | break | endif

    for l:link in vimwiki#link#get_from_file(l:file)
      if resolve(l:link.filename) ==# resolve(l:origin)
        call add(l:locs, {
              \ 'filename' : l:file,
              \ 'text' : empty(l:link.anchor) ? '' : 'Anchor: ' . l:anchor,
              \ 'lnum' : l:link.lnum,
              \ 'col' : l:link.col
              \})
      endif
    endfor
  endfor

  if empty(l:locs)
    echomsg 'Vimwiki: No other file links to this file'
  else
    call setloclist(0, l:locs, 'r')
    lopen
  endif
endfunction

"}}}1

"
" TODO
"
function! vimwiki#page#create_toc() " {{{1
  " collect new headers
  let is_inside_pre_or_math = 0  " 1: inside pre, 2: inside math, 0: outside
  let headers = []
  let headers_levels = [['', 0], ['', 0], ['', 0], ['', 0], ['', 0], ['', 0]]
  for lnum in range(1, line('$'))
    let line_content = getline(lnum)
    if (is_inside_pre_or_math == 1 && line_content =~# g:vimwiki_rxPreEnd) ||
          \ (is_inside_pre_or_math == 2 && line_content =~# g:vimwiki_rxMathEnd)
      let is_inside_pre_or_math = 0
      continue
    endif
    if is_inside_pre_or_math > 0
      continue
    endif
    if line_content =~# g:vimwiki_rxPreStart
      let is_inside_pre_or_math = 1
      continue
    endif
    if line_content =~# g:vimwiki_rxMathStart
      let is_inside_pre_or_math = 2
      continue
    endif
    if line_content !~# g:vimwiki_rxHeader
      continue
    endif
    let h_level = vimwiki#u#count_first_sym(line_content)
    let h_text = vimwiki#u#trim(matchstr(line_content, g:vimwiki_rxHeader))
    if h_text ==# 'Innhald'  " don't include the TOC's header itself
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
    let link = substitute(g:vimwiki_WikiLinkTemplate2, '__LinkUrl__',
          \ '\='."'".'#'.esc_link."'", '')
    let link = substitute(link, '__LinkDescription__', '\='."'".esc_desc."'", '')
    call add(lines, startindent.repeat(indentstring, lvl-1).bullet.link)
  endfor

  let links_rx = '\m^\s*'.vimwiki#u#escape(vimwiki#lst#default_symbol()).' '

  call s:update_listing_in_buffer(lines, 'Innhald', links_rx, 1, 1)
endfunction

" }}}1
function! s:update_listing_in_buffer(strings, start_header, content_regex, default_lnum, create) " {{{1
  " check if the listing is already there
  let already_there = 0

  let header_rx = '\m^\s*'.
        \ substitute(g:vimwiki_rxH1_Template, '__Header__', a:start_header, '')
        \ .'\s*$'

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
        \ . substitute(g:vimwiki_rxH1_Template,
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

"
" TODO
"
function! vimwiki#page#rename() "{{{1
  " Check if current file exists
  if !filereadable(expand('%:p'))
    echom 'Vimwiki Error: Cannot rename "' . expand('%:p')
          \ . '". It does not exist! (New file? Save it before renaming.)'
    return
  endif

  " Ask if user wants to rename
  if input('Rename "' . expand('%:t:r') . '" [y]es/[N]o? ') !~? '^y'
    return
  endif

  " Get new page name
  let l:new = input('Enter new name: ')
  echon "\r"
  if empty(substitute(l:new, '\s', '', 'g'))
    echom 'Vimwiki Error: Cannot rename to an empty filename!'
    return
  endif

  " Expand to full path name, check if already exists
  let l:new_path = expand('%:p:h') . '/' . l:new . '.wiki'
  if filereadable(l:new_path)
    echom 'Vimwiki Error: Cannot rename to "' . l:new_path
          \ . '". File with that name exist!'
    return
  endif

  " Rename current file to l:new_path
  try
    echom 'Vimwiki: Renaming ' . expand('%:t') . ' to '
          \ . fnamemodify(l:new_path, ':t')
    let l:result = rename(expand('%:p'), l:new_path)
    if l:result != 0
      throw 'Cannot rename!'
    end
    setlocal buftype=nofile
  catch
    echom 'Vimwiki Error: Cannot rename "'
          \ . expand('%:t:r') . '" to "' . l:new_path . '"!'
    return
  endtry


  let l:old = [
        \ expand('%:p'),
        \ expand('%:t'),
        \ get(b:, 'vimwiki_prev_link', ''),
        \ ]


  " Save wiki buffers
  let l:bufs = s:get_wiki_buffers()
  for l:buf in l:bufs
    execute ':b ' . escape(l:buf[0], ' ')
    update
    execute 'bwipeout ' . escape(l:buf[0], ' ')
  endfor

  " Update links
  call s:update_wiki_links(l:old[1], l:new)

  " Restore wiki buffers
  for l:buf in l:bufs
    if !resolve(l:buf[0]) ==# resolve(l:old[0])
      call s:open_wiki_buffer(l:buf)
    endif
  endfor

  call s:open_wiki_buffer([l:new_path, l:old[2]])

  echon "\r" . repeat(' ', &columns-1)
  echon "\rVimwiki: Done!"
endfunction

" }}}1
function! s:get_wiki_buffers() " {{{1
  return map(filter(map(filter(range(1, bufnr('$')),
        \       'bufexists(v:val)'),
        \     'fnamemodify(bufname(v:val), '':p'')'),
        \   'v:val =~# ''.wiki$'''),
        \ '[v:val, getbufvar(v:val, ''vimwiki_prev_link'')]')
endfunction

" }}}1
function! s:update_wiki_links(old_fname, new_fname) " {{{1
  let old_fname = a:old_fname
  let new_fname = a:new_fname

  let subdirs = split(a:old_fname, '[/\\]')[: -2]

  " TODO: Use Dictionary here...
  let dirs_keys = ['']
  let dirs_vals = ['']
  if len(subdirs) > 0
    let dirs_keys = ['']
    let dirs_vals = [join(subdirs, '/').'/']
    let idx = 0
    while idx < len(subdirs) - 1
      call add(dirs_keys, join(subdirs[: idx], '/').'/')
      call add(dirs_vals, join(subdirs[idx+1 :], '/').'/')
      let idx = idx + 1
    endwhile
    call add(dirs_keys,join(subdirs, '/').'/')
    call add(dirs_vals, '')
  endif

  let idx = 0
  while idx < len(dirs_keys)
    let dir = dirs_keys[idx]
    let new_dir = dirs_vals[idx]
    call s:update_wiki_links_dir(dir,
          \ new_dir.old_fname, new_dir.new_fname)
    let idx = idx + 1
  endwhile
endfunction

" }}}1
function! s:open_wiki_buffer(item) " {{{1
  silent! call vimwiki#todo#edit_file(':e', a:item[0], '')
  if !empty(a:item[1])
    call setbufvar(a:item[0], "vimwiki_prev_link", a:item[1])
  endif
endfunction

" }}}1
function! s:update_wiki_links_dir(dir, old_fname, new_fname) " {{{1
  let old_fname = substitute(a:old_fname, '[/\\]', '[/\\\\]', 'g')
  let new_fname = a:new_fname

  let old_fname_r = vimwiki#todo#apply_template(
        \ g:vimwiki_WikiLinkMatchUrlTemplate, old_fname, '', '')

  echo ''
  for fname in split(glob(g:vimwiki_path . a:dir . '*.wiki'), '\n')
    echon "\r" . repeat(' ', &columns-1)
    echon "\rUpdating links in: " . fnamemodify(fname, ':t')
    let has_updates = 0
    let dest = []
    for line in readfile(fname)
      if !has_updates && match(line, old_fname_r) != -1
        let has_updates = 1
      endif
      " XXX: any other characters to escape!?
      call add(dest, substitute(line, old_fname_r, escape(new_fname, "&"), "g"))
    endfor
    " add exception handling...
    if has_updates
      call rename(fname, fname.'#vimwiki_upd#')
      call writefile(dest, fname)
      call delete(fname.'#vimwiki_upd#')
    endif
  endfor
endfunction

" }}}1

" vim: fdm=marker sw=2

