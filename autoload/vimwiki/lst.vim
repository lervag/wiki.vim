" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" Toggle checkbox
"
function! vimwiki#lst#toggle_cb(from_line, to_line) "{{{
  let from_item = s:get_corresponding_item(a:from_line)
  if from_item.type == 0 | return | endif

  let parent_items_of_lines = []

  if from_item.cb == ''
    let parent_items_of_lines = []
    for cur_ln in range(from_item.lnum, a:to_line)
      let cur_item = s:get_item(cur_ln)
      let success = s:create_cb(cur_item)
      if success
        let cur_parent_item = s:get_parent(cur_item)
        if index(parent_items_of_lines, cur_parent_item) == -1
          call insert(parent_items_of_lines, cur_parent_item)
        endif
      endif
    endfor
  else
    let rate_first_line = s:get_rate(from_item)
    let new_rate = rate_first_line == 100 ? 0 : 100
    for cur_ln in range(from_item.lnum, a:to_line)
      let cur_item = s:get_item(cur_ln)
      if cur_item.type != 0 && cur_item.cb != ''
        call s:set_state_plus_children(cur_item, new_rate)
        let cur_parent_item = s:get_parent(cur_item)
        if index(parent_items_of_lines, cur_parent_item) == -1
          call insert(parent_items_of_lines, cur_parent_item)
        endif
      endif
    endfor
  endif

  for parent_item in parent_items_of_lines
    call s:update_state(parent_item)
  endfor
endfunction

"}}}1

"
" Stupid amount of utility functions
"
function! s:get_corresponding_item(lnum) "{{{
  let item = s:get_item(a:lnum)
  if item.type != 0
    return item
  endif
  let org_lvl = s:get_level(a:lnum)
  let cur_ln = a:lnum
  while cur_ln > 0
    let cur_lvl = s:get_level(cur_ln)
    let cur_item = s:get_item(cur_ln)
    if cur_lvl < org_lvl && cur_item.type != 0
      return cur_item
    endif
    if cur_lvl < org_lvl
      let org_lvl = cur_lvl
    endif
    let cur_ln = s:get_prev_line(cur_ln)
  endwhile
  return s:empty_item()
endfunction "}}}
function! s:get_item(lnum) "{{{
  let item = {'lnum': a:lnum}
  if a:lnum == 0 || a:lnum > line('$')
    let item.type = 0
    return item
  endif

  let matches = matchlist(getline(a:lnum), g:vimwiki_rxListItem)
  if matches == [] ||
        \ (matches[1] == '' && matches[2] == '') ||
        \ (matches[1] != '' && matches[2] != '')
    let item.type = 0
    return item
  endif

  let item.cb = matches[3]

  if matches[1] != ''
    let item.type = 1
    let item.mrkr = matches[1]
  else
    let item.type = 2
    let item.mrkr = matches[2]
  endif

  return item
endfunction "}}}
function! s:get_level(lnum) "{{{
  if getline(a:lnum) =~# '^\s*$'
    return 0
  endif
  if VimwikiGet('syntax') !=? 'media'
    let level = indent(a:lnum)
  else
    let level = strdisplaywidth(matchstr(getline(a:lnum), s:rx_bullet_chars))-1
    if level < 0
      let level = (indent(a:lnum) == 0) ? 0 : 9999
    endif
  endif
  return level
endfunction "}}}
function! s:get_prev_line(lnum) "{{{
  let prev_line = prevnonblank(a:lnum-1)

  if getline(prev_line) =~# g:vimwiki_rxPreEnd
    let cur_ln = a:lnum - 1
    while 1
      if cur_ln == 0 || getline(cur_ln) =~# g:vimwiki_rxPreStart
        break
      endif
      let cur_ln -= 1
    endwhile
    let prev_line = cur_ln
  endif

  if prev_line < 0 || prev_line > line('$') ||
        \ getline(prev_line) =~# g:vimwiki_rxHeader
    return 0
  endif

  return prev_line
endfunction "}}}
function! s:update_state(item) "{{{
  if a:item.type == 0 || a:item.cb == ''
    return
  endif

  let sum_children_rate = 0
  let count_children_with_cb = 0

  let child_item = s:get_first_child(a:item)

  while 1
    if child_item.type == 0
      break
    endif
    if child_item.cb != ''
      let count_children_with_cb += 1
      let sum_children_rate += s:get_rate(child_item)
    endif
    let child_item = s:get_next_child_item(a:item, child_item)
  endwhile

  if count_children_with_cb > 0
    let new_rate = sum_children_rate / count_children_with_cb
    call s:set_state_recursively(a:item, new_rate)
  else
    let rate = s:get_rate(a:item)
    if rate > 0 && rate < 100
      call s:set_state_recursively(a:item, 0)
    endif
  endif
endfunction "}}}
function! s:create_cb(item) "{{{
  if a:item.type == 0 || a:item.cb != ''
    return 0
  endif

  let new_item = a:item
  let new_item.cb = g:vimwiki_listsyms_list[0]
  call s:substitute_rx_in_line(new_item.lnum,
        \ vimwiki#u#escape(new_item.mrkr) . '\zs\ze', ' [' . new_item.cb . ']')

  call s:update_state(new_item)
  return 1
endfunction "}}}
function! s:substitute_rx_in_line(lnum, pattern, new_string) "{{{
  call setline(a:lnum, substitute(getline(a:lnum), a:pattern, a:new_string,
        \ ''))
endfunction "}}}
function! s:get_first_child(item) "{{{
  if a:item.lnum >= line('$')
    return s:empty_item()
  endif
  let org_lvl = s:get_level(a:item.lnum)
  let cur_item = s:get_item(s:get_next_line(a:item.lnum))
  while 1
    if cur_item.type != 0 && s:get_level(cur_item.lnum) > org_lvl
      return cur_item
    endif
    if cur_item.lnum > line('$') || cur_item.lnum <= 0 ||
          \ s:get_level(cur_item.lnum) <= org_lvl
      return s:empty_item()
    endif
    let cur_item = s:get_item(s:get_next_line(cur_item.lnum))
  endwhile
endfunction "}}}
function! s:get_parent(item) "{{{
  let parent_line = 0

  let cur_ln = prevnonblank(a:item.lnum)
  let child_lvl = s:get_level(cur_ln)
  if child_lvl == 0
    return s:empty_item()
  endif

  while 1
    let cur_ln = s:get_prev_line(cur_ln)
    if cur_ln == 0 | break | endif
    let cur_lvl = s:get_level(cur_ln)
    if cur_lvl < child_lvl
      let cur_item = s:get_item(cur_ln)
      if cur_item.type == 0
        let child_lvl = cur_lvl
        continue
      endif
      let parent_line = cur_ln
      break
    endif
  endwhile
  return s:get_item(parent_line)
endfunction "}}}
function! s:get_rate(item) "{{{
  if a:item.type == 0 || a:item.cb == ''
    return -1
  endif
  let state = a:item.cb
  return index(g:vimwiki_listsyms_list, state) * 25
endfunction "}}}
function! s:set_state(item, new_rate) "{{{
  let new_state = s:rate_to_state(a:new_rate)
  let old_state = s:rate_to_state(s:get_rate(a:item))
  if new_state !=# old_state
    call s:substitute_rx_in_line(a:item.lnum, '\[.]', '['.new_state.']')
    return 1
  else
    return 0
  endif
endfunction "}}}
function! s:set_state_plus_children(item, new_rate) "{{{
  call s:set_state(a:item, a:new_rate)

  let child_item = s:get_first_child(a:item)
  while 1
    if child_item.type == 0
      break
    endif
    if child_item.cb != ''
      call s:set_state_plus_children(child_item, a:new_rate)
    endif
    let child_item = s:get_next_child_item(a:item, child_item)
  endwhile
endfunction "}}}
function! s:rate_to_state(rate) "{{{
  let state = ''
  if a:rate == 100
    let state = g:vimwiki_listsyms_list[4]
  elseif a:rate == 0
    let state = g:vimwiki_listsyms_list[0]
  elseif a:rate >= 67
    let state = g:vimwiki_listsyms_list[3]
  elseif a:rate >= 34
    let state = g:vimwiki_listsyms_list[2]
  else
    let state = g:vimwiki_listsyms_list[1]
  endif
  return state
endfunction "}}}
function! s:set_state_recursively(item, new_rate) "{{{
  let state_changed = s:set_state(a:item, a:new_rate)
  if state_changed
    call s:update_state(s:get_parent(a:item))
  endif
endfunction "}}}
function! s:empty_item() "{{{
  return {'type': 0}
endfunction "}}}
function! s:get_next_line(lnum, ...) "{{{
  if getline(a:lnum) =~# g:vimwiki_rxPreStart
    let cur_ln = a:lnum + 1
    while cur_ln <= line('$') &&
          \ getline(cur_ln) !~# g:vimwiki_rxPreEnd
      let cur_ln += 1
    endwhile
    let next_line = cur_ln
  else
    let next_line = nextnonblank(a:lnum+1)
  endif

  if a:0 > 0 && getline(next_line) =~# g:vimwiki_rxHeader
    let next_line = s:get_next_line(next_line, 1)
  endif

  if next_line < 0 || next_line > line('$') ||
        \ (getline(next_line) =~# g:vimwiki_rxHeader && a:0 == 0)
    return 0
  endif

  return next_line
endfunction "}}}
function! s:get_next_child_item(parent, child) "{{{
  if a:parent.type == 0 | return s:empty_item() | endif
  let parent_lvl = s:get_level(a:parent.lnum)
  let cur_ln = s:get_last_line_of_item_incl_children(a:child)
  while 1
    let next_line = s:get_next_line(cur_ln)
    if next_line == 0 || s:get_level(next_line) <= parent_lvl
      break
    endif
    let cur_ln = next_line
    let cur_item = s:get_item(cur_ln)
    if cur_item.type > 0
      return cur_item
    endif
  endwhile
  return s:empty_item()
endfunction "}}}
function! s:get_last_line_of_item_incl_children(item) "{{{
  let cur_ln = a:item.lnum
  let org_lvl = s:get_level(a:item.lnum)
  while 1
    let next_line = s:get_next_line(cur_ln)
    if next_line == 0 || s:get_level(next_line) <= org_lvl
      return cur_ln
    endif
    let cur_ln = next_line
  endwhile
endfunction "}}}

" {{{ Probably dead stuff

function! vimwiki#lst#default_symbol() "{{{
  return g:vimwiki_list_markers[0]
endfunction "}}}
function! vimwiki#lst#get_list_margin() "{{{
  if VimwikiGet('list_margin') < 0
    return &sw
  else
    return VimwikiGet('list_margin')
  endif
endfunction "}}}
function! vimwiki#lst#adjust_numbered_list() "{{{
  let cur_item = s:get_corresponding_item(line('.'))
  if cur_item.type == 0 | return | endif
  call s:adjust_numbered_list(cur_item, 1, 0)
  call s:update_state(s:get_parent(cur_item))
endfunction "}}}
function! vimwiki#lst#adjust_whole_buffer() "{{{
  let cur_ln = 1
  while 1
    let cur_item = s:get_item(cur_ln)
    if cur_item.type != 0
      let cur_item = s:adjust_numbered_list(cur_item, 0, 1)
    endif
    let cur_ln = s:get_next_line(cur_item.lnum, 1)
    if cur_ln <= 0 || cur_ln > line('$')
      return
    endif
  endwhile
endfunction "}}}
function! vimwiki#lst#setup_marker_infos() "{{{
  let s:rx_bullet_chars = '['.join(keys(g:vimwiki_bullet_types), '').']\+'

  let s:multiple_bullet_chars = []
  for i in keys(g:vimwiki_bullet_types)
    if g:vimwiki_bullet_types[i] == 1
      call add(s:multiple_bullet_chars, i)
    endif
  endfor

  let s:number_kinds = []
  let s:number_divisors = ""
  for i in g:vimwiki_number_types
    call add(s:number_kinds, i[0])
    let s:number_divisors .= vimwiki#u#escape(i[1])
  endfor

  let s:char_to_rx = {'1': '\d\+', 'i': '[ivxlcdm]\+', 'I': '[IVXLCDM]\+',
        \ 'a': '\l\{1,2}', 'A': '\u\{1,2}'}

  "create regexp for bulleted list items
  let g:vimwiki_rxListBullet = join( map(keys(g:vimwiki_bullet_types),
        \'vimwiki#u#escape(v:val).repeat("\\+", g:vimwiki_bullet_types[v:val])'
        \ ) , '\|')

  "create regex for numbered list items
  if !empty(g:vimwiki_number_types)
    let g:vimwiki_rxListNumber = '\C\%('
    for type in g:vimwiki_number_types[:-2]
      let g:vimwiki_rxListNumber .= s:char_to_rx[type[0]] .
            \ vimwiki#u#escape(type[1]) . '\|'
    endfor
    let g:vimwiki_rxListNumber .= s:char_to_rx[g:vimwiki_number_types[-1][0]].
          \ vimwiki#u#escape(g:vimwiki_number_types[-1][1]) . '\)'
  else
    "regex that matches nothing
    let g:vimwiki_rxListNumber = '$^'
  endif

  "the user can set the listsyms as string, but vimwiki needs a list
  let g:vimwiki_listsyms_list = split(g:vimwiki_listsyms, '\zs')
endfunction "}}}

" }}}

" vim: fdm=marker sw=2
