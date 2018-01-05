" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#page#delete() abort "{{{1
  let l:input_response = input('Delete "' . expand('%') . '" [y]es/[N]o? ')
  if l:input_response !~? '^y' | return | endif

  let l:filename = expand('%:p')
  try
    call delete(l:filename)
  catch /.*/
    echomsg 'wiki Error: Cannot delete "' . expand('%:t:r') . '"!'
    return
  endtry

  call wiki#nav#return()
  execute 'bdelete! ' . escape(l:filename, ' ')
endfunction

"}}}1
function! wiki#page#rename() abort "{{{1
  " Check if current file exists
  if !filereadable(expand('%:p'))
    echom 'wiki Error: Cannot rename "' . expand('%:p')
          \ . '". It does not exist! (New file? Save it before renaming.)'
    return
  endif

  if b:wiki.in_journal
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
    echom 'wiki Error: Cannot rename to an empty filename!'
    return
  endif

  " Expand to full path name, check if already exists
  let l:new.path = expand('%:p:h') . '/' . l:new.name . '.wiki'
  if filereadable(l:new.path)
    echom 'wiki Error: Cannot rename to "' . l:new.path
          \ . '". File with that name exist!'
    return
  endif

  " Rename current file to l:new.path
  try
    echom 'wiki: Renaming ' . expand('%:t')
          \ . ' to ' . fnamemodify(l:new.path, ':t')
    if rename(expand('%:p'), l:new.path) != 0
      throw 'Cannot rename!'
    end
    setlocal buftype=nofile
  catch
    echom 'wiki Error: Cannot rename "'
          \ . expand('%:t:r') . '" to "' . l:new.path . '"!'
    return
  endtry

  " Store some info from old buffer
  let l:old = {
        \ 'path' : expand('%:p'),
        \ 'name' : expand('%:t:r'),
        \ 'prev_link' : get(b:, 'wiki_prev_link', ''),
        \}

  " Get list of open wiki buffers
  let l:bufs = map(filter(map(filter(range(1, bufnr('$')),
        \       'buflisted(v:val)'),
        \     'fnamemodify(bufname(v:val), '':p'')'),
        \   'v:val =~# ''.wiki$'''),
        \ '[v:val, getbufvar(v:val, ''wiki.prev_link'')]')

  " Save and close wiki buffers
  for [l:bufname, l:dummy] in l:bufs
    execute 'buffer' fnameescape(l:bufname)
    update
    execute 'bwipeout' fnameescape(l:bufname)
  endfor

  " Update links
  call s:rename_update_links(l:old.name, l:new.name)

  " Restore wiki buffers
  for [l:bufname, l:prev_link] in l:bufs
    if resolve(l:bufname) ==# resolve(l:old.path)
      let l:url = wiki#url#parse(
            \ l:new.name,
            \ { 'origin' : l:old.prev_link })
    else
      let l:url = wiki#url#parse(
            \ fnamemodify(l:bufname, ':t:r'),
            \ { 'prev_link' : l:prev_link })
    endif
    silent call l:url.open()
  endfor
endfunction

" }}}1
function! wiki#page#create_toc() abort " {{{1
  let l:winsave = winsaveview()
  let l:start = 1
  let l:entries = []
  let l:anchor_stack = []

  "
  " Create toc entries
  "
  for l:lnum in range(1, line('$'))
    if wiki#u#is_code(l:lnum) | continue | endif

    " Get line - check for header
    let l:line = getline(l:lnum)
    if l:line !~# wiki#rx#header() | continue | endif

    " Parse current header
    let l:level = len(matchstr(l:line, '^#*'))
    let l:header = matchlist(l:line, wiki#rx#header_items())[2]
    if l:header ==# 'Innhald' | continue | endif

    " Update header stack in order to have well defined anchor
    let l:depth = len(l:anchor_stack)
    if l:depth >= l:level
      call remove(l:anchor_stack, l:level-1, l:depth-1)
    endif
    call add(l:anchor_stack, l:header)
    let l:anchor = '#' . join(l:anchor_stack, '#')

    " Add current entry
    call add(l:entries, repeat(' ', shiftwidth()*(l:level-1)) . '- '
          \ . wiki#link#template_wiki(l:anchor, l:header))
  endfor

  let l:syntax = &l:syntax
  setlocal syntax=off

  "
  " Delete TOC if it exists
  "
  for l:lnum in range(1, line('$'))
    if getline(l:lnum) =~# '^\s*#[^#]\+Innhald'
      let l:start = l:lnum
      let l:end = l:start + (getline(l:lnum+1) =~# '^\s*$' ? 2 : 1)
      while l:end <= line('$') && getline(l:end) =~# '^\s*- '
        let l:end += 1
      endwhile

      let l:foldenable = &l:foldenable
      setlocal nofoldenable
      silent execute printf('%d,%ddelete _', l:start, l:end - 1)
      let &l:foldenable = l:foldenable

      break
    endif
  endfor

  "
  " Add updated TOC
  "
  call append(l:start - 1, '# Innhald')
  let l:length = len(l:entries)
  for l:i in range(l:length)
    call append(l:start + l:i, l:entries[l:i])
  endfor
  if getline(l:start + l:length + 1) !=# ''
    call append(l:start + l:length, '')
  endif
  call append(l:start, '')

  "
  " Restore syntax and view
  "
  let &l:syntax = l:syntax
  call winrestview(l:winsave)
endfunction

" }}}1

function! s:rename_update_links(old, new) abort " {{{1
  let l:pattern  = '\v\[\[\/?\zs' . a:old . '\ze%(#.*)?%(\|.*)?\]\]'
  let l:pattern .= '|\[.*\]\[\zs' . a:old . '\ze%(#.*)?\]'
  let l:pattern .= '|\[.*\]\(\/?\zs' . a:old . '\ze%(#.*)?\)'
  let l:pattern .= '|\[\zs' . a:old . '\ze%(#.*)?\]\[\]'

  let l:num_files = 0
  let l:num_links = 0

  for l:file in glob(wiki#get_root() . '**/*.wiki', 0, 1)
    let l:updates = 0
    let l:lines = []
    for l:line in readfile(l:file)
      if match(l:line, l:pattern) != -1
        let l:updates = 1
        let l:num_links += 1
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
      let l:num_files += 1
    endif
  endfor
  echom printf('Updated %d links in %d files', l:num_links, l:num_files)
endfunction

" }}}1

