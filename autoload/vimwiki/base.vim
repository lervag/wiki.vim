" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#base#file_pattern(files) " {{{1
  return '\V\%('.join(a:files, '\|').'\)\m'
endfunction

" }}}1
function! vimwiki#base#current_subdir() " {{{1
  return vimwiki#todo#subdir(vimwiki#opts#get('path'), expand('%:p'))
endfunction

" }}}1
function! vimwiki#base#invsubdir(subdir) " {{{1
  return substitute(a:subdir, '[^/\.]\+/', '../', 'g')
endfunction

" }}}1
function! vimwiki#base#system_open_link(url) " {{{1
  call system('xdg-open ' . shellescape(a:url).' &')
endfunction

" }}}1
function! vimwiki#base#get_globlinks_escaped() abort " {{{1
  " change to the directory of the current file
  let orig_pwd = getcwd()
  lcd! %:h
  " all path are relative to the current file's location
  let globlinks = glob('*.wiki', 1) . '\n'
  " remove extensions
  let globlinks = substitute(globlinks, '\.wiki\ze\n', '', 'g')
  " restore the original working directory
  exe 'lcd! '.orig_pwd
  " convert to a List
  let lst = split(globlinks, '\n')
  " Apply fnameescape() to each item
  call map(lst, 'fnameescape(v:val)')
  " Convert back to newline-separated list
  let globlinks = join(lst, "\n")
  " return all escaped links as a single newline-separated string
  return globlinks
endfunction

" }}}1
function! vimwiki#base#generate_links() " {{{1
  let lines = []

  let links = vimwiki#base#get_wikilinks(0, 0)
  call sort(links)

  let bullet = repeat(' ', vimwiki#lst#get_list_margin()).
        \ vimwiki#lst#default_symbol().' '
  for link in links
    let abs_filepath = vimwiki#path#abs_path_of_link(link)
    let file_path = vimwiki#path#path_norm(abs_filepath)
    let diary_path = vimwiki#path#path_norm(vimwiki#opts#get('path') . 'journal/')
    if file_path !~# '^'.vimwiki#u#escape(diary_path)
      call add(lines, bullet.
            \ substitute(g:vimwiki_WikiLinkTemplate1, '__LinkUrl__', '\='."'".link."'", ''))
    endif
  endfor

  let links_rx = '\m^\s*'.vimwiki#u#escape(vimwiki#lst#default_symbol()).' '

  call vimwiki#base#update_listing_in_buffer(lines, 'Generated Links', links_rx,
        \ line('$')+1, 1)
endfunction

" }}}1
function! vimwiki#base#goto(...) " {{{1
  let key = a:1
  let anchor = a:0 > 1 ? a:2 : ''

  call vimwiki#todo#edit_file(':e',
        \ vimwiki#opts#get('path') . key . '.wiki',
        \ anchor)
endfunction

" }}}1
function! vimwiki#base#find_files(is_not_diary, directories_only) " {{{1
  let root_directory = vimwiki#opts#get('path')
        \ . (a:is_not_diary >= 0 ? '' : 'journal/')

  let ext = a:directories_only ? '/' : '.wiki'

  return split(globpath(root_directory, '**/*'.ext), '\n')
endfunction

" }}}1
function! vimwiki#base#get_wikilinks(also_absolute_links) " {{{1
  let files = vimwiki#base#find_files(0, 0)
  let cwd = vimwiki#path#wikify_path(expand('%:p:h'))
  let result = []
  for wikifile in files
    let wikifile = fnamemodify(wikifile, ':r')
    let wikifile = vimwiki#path#relpath(cwd, wikifile)
    call add(result, wikifile)
  endfor
  if a:also_absolute_links
    let cwd = vimwiki#opts#get('path')
    for wikifile in files
      let wikifile = fnamemodify(wikifile, ':r')
      let wikifile = '/' . vimwiki#path#relpath(cwd, wikifile)
      call add(result, wikifile)
    endfor
  endif
  return result
endfunction

" }}}1
function! vimwiki#base#get_wiki_directories(wiki_nr) " {{{1
  " Returns: a list containing the links to all directories from the current file
  let dirs = vimwiki#base#find_files(a:wiki_nr, 1)
  if a:wiki_nr == 0
    let cwd = vimwiki#path#wikify_path(expand('%:p:h'))
    let root_dir = vimwiki#opts#get('path')
  else
    let cwd = vimwiki#opts#get('path', a:wiki_nr)
  endif
  let result = ['./']
  for wikidir in dirs
    let wikidir_relative = vimwiki#path#relpath(cwd, wikidir)
    call add(result, wikidir_relative)
    if a:wiki_nr == 0
      let wikidir_absolute = '/'.vimwiki#path#relpath(root_dir, wikidir)
      call add(result, wikidir_absolute)
    endif
  endfor
  return result
endfunction

" }}}1
function! vimwiki#base#get_anchors(filename, syntax) " {{{1
  if !filereadable(a:filename)
    return []
  endif

  let rxheader = g:vimwiki_{a:syntax}_header_search
  let rxbold = g:vimwiki_{a:syntax}_bold_search
  let rxtag = g:vimwiki_{a:syntax}_tag_search

  let anchor_level = ['', '', '', '', '', '', '']
  let anchors = []
  let current_complete_anchor = ''
  for line in readfile(a:filename)

    " collect headers
    let h_match = matchlist(line, rxheader)
    if !empty(h_match)
      let header = vimwiki#u#trim(h_match[2])
      let level = len(h_match[1])
      call add(anchors, header)
      let anchor_level[level-1] = header
      for l in range(level, 6)
        let anchor_level[l] = ''
      endfor
      if level == 1
        let current_complete_anchor = header
      else
        let current_complete_anchor = ''
        for l in range(level-1)
          if anchor_level[l] != ''
            let current_complete_anchor .= anchor_level[l].'#'
          endif
        endfor
        let current_complete_anchor .= header
        call add(anchors, current_complete_anchor)
      endif
    endif

    " collect bold text (there can be several in one line)
    let bold_count = 1
    while 1
      let bold_text = matchstr(line, rxbold, 0, bold_count)
      if bold_text == ''
        break
      endif
      call add(anchors, bold_text)
      if current_complete_anchor != ''
        call add(anchors, current_complete_anchor.'#'.bold_text)
      endif
      let bold_count += 1
    endwhile

    " collect tags text (there can be several in one line)
    let tag_count = 1
    while 1
      let tag_group_text = matchstr(line, rxtag, 0, tag_count)
      if tag_group_text == ''
        break
      endif
      for tag_text in split(tag_group_text, ':')
        call add(anchors, tag_text)
        if current_complete_anchor != ''
          call add(anchors, current_complete_anchor.'#'.tag_text)
        endif
      endfor
      let tag_count += 1
    endwhile

  endfor

  return anchors
endfunction

" }}}1
function! vimwiki#base#search_word(wikiRx, cmd) " {{{1
  let match_line = search(a:wikiRx, 's'.a:cmd)
  if match_line == 0
    echomsg 'Vimwiki: Wiki link not found'
  endif
endfunction

" }}}1
function! vimwiki#base#matchstr_at_cursor(wikiRX) " {{{1
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    return strpart(line, ebeg, elen)
  else
    return ""
  endif
endf "}}}
function! vimwiki#base#replacestr_at_cursor(wikiRX, sub) " {{{1
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    " TODO: There might be problems with Unicode chars...
    let newline = strpart(line, 0, ebeg).a:sub.strpart(line, ebeg+elen)
    call setline(line('.'), newline)
  endif
endf "}}}
function! vimwiki#base#update_listing_in_buffer(strings, start_header, content_regex, default_lnum, create) " {{{1
  " apparently, Vim behaves strange when files change while in diff mode
  if &diff || &readonly
    return
  endif

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

" vim: fdm=marker sw=2
