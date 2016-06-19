" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" Main functions
"
function! vimwiki#diary#make_note(...) "{{{
  call vimwiki#todo#open_link('edit',
        \ 'diary:' . (a:0 > 0 ? a:1 : s:diary_date_link()),
        \ s:diary_index())
endfunction "}}}
function! vimwiki#diary#copy_note() " {{{
  let l:current = expand('%:t:r')

  " Get next weekday
  let l:candidate = systemlist('date -d "' . l:current . ' +1 day" +%F')[0]
  while systemlist('date -d "' . l:candidate . '" +%u')[0] > 5
    let l:candidate = systemlist('date -d "' . l:candidate . ' +1 day" +%F')[0]
  endwhile

  let l:next = expand('%:p:h') . '/' . l:candidate . '.wiki'
  if !filereadable(l:next)
    execute 'write' l:next
  endif

  call vimwiki#diary#goto_next_day()
endfunction

" }}}1
function! vimwiki#diary#goto_next_day() "{{{
  let [l:index, l:entries] = s:get_position_links(expand('%:t:r'))

  if l:index == (len(l:entries) - 1)
    return
  endif

  if l:index != -1 && l:index < len(l:entries) - 1
    let l:link = 'diary:' . l:entries[l:index+1]
  else
    let l:link = 'diary:' . s:diary_date_link()
  endif

  call vimwiki#todo#open_link('edit ', l:link)
endfunction "}}}
function! vimwiki#diary#goto_prev_day() "{{{
  let [l:index, l:entries] = s:get_position_links(expand('%:t:r'))

  if l:index == 0
    return
  endif

  if l:index > 0
    let l:link = 'diary:' . l:entries[l:index-1]
  else
    let l:link = 'diary:' . s:diary_date_link()
  endif

  call vimwiki#todo#open_link('edit ', l:link)
endfunction "}}}
function! vimwiki#diary#generate_diary_section() "{{{
  let current_file = vimwiki#path#path_norm(expand("%:p"))
  let diary_file = vimwiki#path#path_norm(s:diary_index())
  if resolve(current_file) = resolve(diary_file)
    let content_rx = '^\%(\s*\* \)\|\%(^\s*$\)\|\%('.g:vimwiki_rxHeader.'\)'
    call vimwiki#base#update_listing_in_buffer(s:format_diary(),
          \ vimwiki#opts#get('diary_header'), content_rx, line('$')+1, 1)
  else
    echomsg 'Vimwiki Error: You can generate diary links only in a diary index page!'
  endif
endfunction "}}}

"
" Calendar.vim integration
"
function! vimwiki#diary#calendar_action(day, month, year, week, dir) "{{{
  let day = s:prefix_zero(a:day)
  let month = s:prefix_zero(a:month)

  let link = a:year.'-'.month.'-'.day
  if winnr('#') == 0
    if a:dir ==? 'V'
      vsplit
    else
      split
    endif
  else
    wincmd p
    if !&hidden && &modified
      new
    endif
  endif

  call vimwiki#diary#make_note(link)
endfunction "}}}
function! vimwiki#diary#calendar_sign(day, month, year) "{{{
  let day = s:prefix_zero(a:day)
  let month = s:prefix_zero(a:month)
  let sfile = vimwiki#opts#get('path').vimwiki#opts#get('diary_rel_path').
        \ a:year.'-'.month.'-'.day.vimwiki#opts#get('ext')
  return filereadable(expand(sfile))
endfunction "}}}

"
" Helpers
"
function! s:prefix_zero(num) "{{{
  if a:num < 10
    return '0'.a:num
  endif
  return a:num
endfunction "}}}
function! s:get_date_link(fmt) "{{{
  return strftime(a:fmt)
endfunction "}}}
function! s:diary_index() "{{{
  return vimwiki#opts#get('path')
        \ . vimwiki#opts#get('diary_rel_path')
        \ . vimwiki#opts#get('diary_index')
        \ . vimwiki#opts#get('ext')
endfunction "}}}
function! s:diary_date_link() "{{{
  return s:get_date_link(vimwiki#opts#get('diary_link_fmt'))
endfunction "}}}
function! s:get_position_links(link) "{{{
  let idx = -1
  let links = []
  if a:link =~# '^\d\{4}-\d\d-\d\d'
    let links = keys(s:get_diary_links())
    " include 'today' into links
    if index(links, s:diary_date_link()) == -1
      call add(links, s:diary_date_link())
    endif
    call sort(links)
    let idx = index(links, a:link)
  endif
  return [idx, links]
endfunction "}}}
function! s:get_month_name(month) "{{{
  return g:vimwiki_diary_months[str2nr(a:month)]
endfunction "}}}

"
" Diary index stuff
"
let s:vimwiki_max_scan_for_caption = 5
function! s:read_captions(files) "{{{
  let result = {}
  for fl in a:files
    " remove paths and extensions
    let fl_key = fnamemodify(fl, ':t:r')

    if filereadable(fl)
      for line in readfile(fl, '', s:vimwiki_max_scan_for_caption)
        if line =~# g:vimwiki_rxHeader && !has_key(result, fl_key)
          let result[fl_key] = vimwiki#u#trim(matchstr(line, g:vimwiki_rxHeader))
        endif
      endfor
    endif

    if !has_key(result, fl_key)
      let result[fl_key] = ''
    endif

  endfor
  return result
endfunction "}}}
function! s:get_diary_links() "{{{
  let rx = '^\d\{4}-\d\d-\d\d'
  let s_files = glob(vimwiki#opts#get('path').vimwiki#opts#get('diary_rel_path').'*'.vimwiki#opts#get('ext'))
  let files = split(s_files, '\n')
  call filter(files, 'fnamemodify(v:val, ":t") =~# "'.escape(rx, '\').'"')

  " remove backup files (.wiki~)
  call filter(files, 'v:val !~# ''.*\~$''')

  let links_with_captions = s:read_captions(files)

  return links_with_captions
endfunction "}}}
function! s:group_links(links) "{{{
  let result = {}
  let p_year = 0
  let p_month = 0
  for fl in sort(keys(a:links))
    let year = strpart(fl, 0, 4)
    let month = strpart(fl, 5, 2)
    if p_year != year
      let result[year] = {}
      let p_month = 0
    endif
    if p_month != month
      let result[year][month] = {}
    endif
    let result[year][month][fl] = a:links[fl]
    let p_year = year
    let p_month = month
  endfor
  return result
endfunction "}}}
function! s:sort(lst) "{{{
  if vimwiki#opts#get("diary_sort") ==? 'desc'
    return reverse(sort(a:lst))
  else
    return sort(a:lst)
  endif
endfunction "}}}
function! s:format_diary() "{{{
  let result = []

  let g_files = s:group_links(s:get_diary_links())

  for year in s:sort(keys(g_files))
    call add(result, '')
    call add(result, substitute(g:vimwiki_rxH2_Template, '__Header__', year , ''))

    for month in s:sort(keys(g_files[year]))
      call add(result, '')
      call add(result, substitute(g:vimwiki_rxH3_Template, '__Header__', s:get_month_name(month), ''))

      for [fl, cap] in s:sort(items(g_files[year][month]))
        if empty(cap)
          let entry = substitute(g:vimwiki_WikiLinkTemplate1, '__LinkUrl__', fl, '')
          let entry = substitute(entry, '__LinkDescription__', cap, '')
          call add(result, repeat(' ', &sw).'* '.entry)
        else
          let entry = substitute(g:vimwiki_WikiLinkTemplate2, '__LinkUrl__', fl, '')
          let entry = substitute(entry, '__LinkDescription__', cap, '')
          call add(result, repeat(' ', &sw).'* '.entry)
        endif
      endfor

    endfor
  endfor

  return result
endfunction "}}}

" vim: fdm=marker sw=2
