" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#journal#make_note(...) " {{{1
  let l:date = (a:0 > 0 ? a:1 : strftime('%Y-%m-%d'))
  call wiki#url#parse('journal:' . l:date).open()
endfunction

" }}}1
function! wiki#journal#copy_note() " {{{1
  let l:next_day = wiki#date#get_next_weekday(expand('%:t:r'))

  let l:next_entry = g:wiki.journal . l:next_day . '.wiki'
  if !filereadable(l:next_entry)
    execute 'write' l:next_entry
  endif

  call wiki#url#parse('journal:' . l:next_day).open()
endfunction

" }}}1
function! wiki#journal#go(step) " {{{1
  let l:links = s:get_links()
  let l:index = index(l:links, expand('%:t:r'))
  let l:target = l:index + a:step

  if l:target >= len(l:links) || l:target <= 0
    return
  endif

  call wiki#url#parse('journal:' . l:links[l:target]).open()
endfunction

" }}}1
function! wiki#journal#go_to_week() " {{{1
  let l:date = expand('%:r') =~# '\d\d\d\d-\d\d-\d\d'
        \ ? expand('%:r')
        \ : strftime('%F')
  call wiki#url#parse('journal:' . l:date[:3]
        \ . '_w' . wiki#date#get_week(l:date)).open()
endfunction

" }}}1
function! wiki#journal#go_to_month() " {{{1
  let l:date = expand('%:r') =~# '\d\d\d\d-\d\d-\d\d'
        \ ? expand('%:r')
        \ : strftime('%F')
  call wiki#url#parse('journal:' . l:date[:3]
        \ . '_m' . wiki#date#get_month(l:date)).open()
endfunction

" }}}1

function! wiki#journal#prefill_summary_weekly(year, week) " {{{1
  let l:links = map(filter(
        \   wiki#date#get_week_dates(a:week, a:year),
        \   'filereadable(v:val . ''.wiki'')'),
        \ '''journal:'' . v:val')

  let l:lines = []
  let l:entries = map(copy(l:links), 's:parse_entry(v:val)')
  for l:project in s:project_list
    let l:first = 1
    for l:entry in l:entries
      if has_key(l:entry, l:project)
        if l:first
          let l:lines += ['']
          let l:lines += l:entry[l:project]
        else
          let l:lines += l:entry[l:project][1:]
        endif
        let l:first = 0
      endif
    endfor
  endfor

  let l:title = '# Samandrag veke ' . a:week . ', ' . a:year

  call append(0, [l:title, ''] + l:links + l:lines)
endfunction

" }}}1
function! wiki#journal#prefill_summary_monthly(year, month) " {{{1
  let [l:pre, l:weeks, l:post] = wiki#date#decompose_month(a:month, a:year)
  let l:links = copy(l:pre)
        \ + map(l:weeks, 'a:year . ''_w'' . v:val')
        \ + copy(l:post)

  call filter(l:links, 'filereadable(v:val . ''.wiki'')')
  call map(l:links, '''journal:'' . v:val')

  let l:lines = []
  let l:entries = map(copy(l:links), 's:parse_entry(v:val)')
  for l:project in s:project_list
    let l:first = 1
    for l:entry in l:entries
      if has_key(l:entry, l:project)
        if l:first
          let l:lines += ['']
          let l:lines += l:entry[l:project]
        else
          let l:lines += l:entry[l:project][1:]
        endif
        let l:first = 0
      endif
    endfor
  endfor

  let l:title = '# Samandrag frå '
        \ . wiki#date#get_month_name(a:month) . ' ' . a:year

  call append(0, [l:title, ''] + l:links + l:lines)
endfunction

" }}}1

function! s:get_links() " {{{1
  let l:current = expand('%:t:r')
  let l:regex_days = '\d\{4}-\d\d-\d\d'
  let l:regex_weeks = '\d\{4}_w\d\d'
  let l:regex_months = '\d\{4}_m\d\d'

  if l:current =~# l:regex_days
    return s:get_links_generic(l:regex_days, '%Y-%m-%d')
  elseif l:current =~# l:regex_weeks
    return s:get_links_generic(l:regex_weeks, '%Y_w%W')
  elseif l:current =~# l:regex_months
    return s:get_links_generic(l:regex_months, '%Y_m%m')
  else
    return []
  endif
endfunction

" }}}1
function! s:get_links_generic(rx, fmt) " {{{1
  let l:links = filter(map(glob(g:wiki.journal . '*.wiki', 0, 1),
        \   'fnamemodify(v:val, '':t:r'')'),
        \ 'v:val =~# a:rx')

  for l:cand in [
        \ strftime(a:fmt),
        \ expand('%:r'),
        \]
    if l:cand =~# a:rx && index(l:links, l:cand) == -1
      call add(l:links, l:cand)
      let l:sort = 1
    endif
  endfor

  return get(l:, 'sort', 0) ? sort(l:links) : l:links
endfunction

" }}}1

let s:project_list = [
      \ 'Diverse',
      \ 'Leiested',
      \ 'Tekna',
      \ 'Sommerjobb-administrasjon',
      \ '3dmf',
      \ 'NanoHX',
      \ 'FerroCool 2',
      \ 'FerroCool',
      \ 'RPT',
      \]
let s:project_title = join(s:project_list, '\|')
function! s:parse_entry(link) " {{{1
  let l:link = wiki#url#parse(a:link)

  let l:entries = {}
  let l:new_entry = 1
  let l:title = ''
  let l:lines = []
  for l:line in readfile(l:link.path)
    "
    " Ignore everything after title lines
    "
    if l:line =~# '^\#' | break | endif

    "
    " Empty lines separate entries
    "
    if l:line =~# '^\s*$'
      if !empty(l:lines)
        let l:entries[l:title] = l:lines
      endif
      let l:ignore = 0
      let l:new_entry = 1
      let l:title = ''
      let l:lines = []
      continue
    endif

    "
    " Ignore time tables
    "
    if l:line =~# '^\*Timeoversikt\|^\s*|-\+'
      let l:ignore = 1
    endif

    if l:ignore | continue | endif

    "
    " Detect header of entries
    "
    if l:new_entry
      if l:line =~# s:project_title
        let l:new_entry = 0
        let l:title = matchstr(l:line, s:project_title)
        call add(l:lines, l:line)
      endif
      continue
    endif

    if !empty(l:title)
      call add(l:lines, l:line)
    endif
  endfor

  return l:entries
endfunction

" }}}1

" vim: fdm=marker sw=2
