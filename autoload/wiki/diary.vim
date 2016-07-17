" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#diary#make_note(...) " {{{1
  let l:date = (a:0 > 0 ? a:1 : strftime('%Y-%m-%d'))
  call wiki#url#parse('diary:' . l:date).open()
endfunction

" }}}1
function! wiki#diary#copy_note() " {{{1
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

  call wiki#diary#go(1)
endfunction

" }}}1
function! wiki#diary#go(step) " {{{1
  let l:links = s:get_links()
  let l:index = index(l:links, expand('%:t:r'))
  let l:target = l:index + a:step

  if l:target >= len(l:links) || l:target <= 0
    return
  endif

  call wiki#url#parse('diary:' . l:links[l:target]).open()
endfunction

" }}}1
function! wiki#diary#go_weekly() " {{{1
  let l:date = expand('%:r') =~# '\d\d\d\d-\d\d-\d\d'
        \ ? expand('%:r')
        \ : strftime('%F')
  let l:week = systemlist('date -d ' . l:date . ' +%W')[0]
  call wiki#url#parse('diary:' . l:date[:3] . '_w' . l:week).open()

  if !filereadable(expand('%'))
    let l:dow = systemlist('date -d ' . l:date . ' +%u')[0]
    let l:days = map(range(1-l:dow, 7-l:dow),
          \   'systemlist(''date +%F -d "'
          \               . l:date . ' '' . v:val . '' days"'')[0]')
    call filter(l:days, 'filereadable(v:val . ''.wiki'')')

    let l:lines = ['# Samandrag veke ' . l:week . ', ' . l:date[:3]]
    let l:lines += ['']
    let l:lines += l:days

    call append(0, l:lines)
  endif
endfunction

" }}}1
function! wiki#diary#go_monthly() " {{{1
  let l:date = expand('%:r') =~# '\d\d\d\d-\d\d-\d\d'
        \ ? expand('%:r')
        \ : strftime('%F')
  let l:month = systemlist('date +%m -d ' . l:date)[0]
  call wiki#url#parse('diary:' . l:date[:3] . '_m' . l:month).open()

  if !filereadable(expand('%'))
    let l:days_in_month = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
    if systemlist('date +%F -d ' . l:date[:3] . '-02-29')[0] =~# '^\d\d\d\d'
      let l:days_in_month[1] = 29
    endif
    let l:ndays = l:days_in_month[l:month-1]
    let l:days = map(range(1, l:ndays), 'printf(''%s%02d'', l:date[:7], v:val)')
    let l:first_monday = (9 - systemlist('date +%u -d ' . l:days[0])[0]) % 7
    let l:nweeks = (l:ndays - l:first_monday + 1)/7
    let l:remaining_days = l:ndays - l:nweeks*7 - l:first_monday + 1
    let l:first_week = systemlist('date +%W -d ' . l:days[l:first_monday-1])[0]
    let l:weeks = []
    for l:i in range(l:nweeks)
      let l:weeks += [l:first_week+l:i]
    endfor

    let l:days_pre = l:first_monday > 1
          \ ? l:days[:l:first_monday-2] : []
    let l:days_post = l:remaining_days > 0
          \ ? l:days[-l:remaining_days:] : []

    PP l:days_pre
    PP l:weeks
    PP l:days_post

"     PP l:first
"     PP l:last

    " call filter(l:days, 'filereadable(v:val . ''.wiki'')')
    " PP l:days

"     let l:months = [
"           \ 'januar',
"           \ 'februar',
"           \ 'mars',
"           \ 'april',
"           \ 'mai',
"           \ 'juni',
"           \ 'juli',
"           \ 'august',
"           \ 'september',
"           \ 'oktober',
"           \ 'november',
"           \ 'desember',
"           \]
"     call append(0, [
"           \ '# Samandrag frå ' . l:months[l:month] . ' ' . l:date[:3],
"           \])
  endif
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
  let l:links = filter(map(glob(g:wiki.diary . '*.wiki', 0, 1),
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

" vim: fdm=marker sw=2
