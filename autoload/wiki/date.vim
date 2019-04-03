" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#date#format(date, format) abort " {{{1
  return s:date(a:date, a:format)
endfunction

" }}}1
function! wiki#date#offset(date, offset) abort " {{{1
  return s:date_offset(a:date, a:offset)
endfunction

" }}}1
function! wiki#date#get_day_of_week(date) abort " {{{1
  return s:date(a:date, '%u')
endfunction

" }}}1
function! wiki#date#get_week(date) abort " {{{1
  return s:date(a:date, '%V')
endfunction

" }}}1
function! wiki#date#get_week_dates(...) abort " {{{1
  "
  " Argument: Either a single date string, or a week number and a year
  "
  if a:0 == 1
    let l:date = a:1
    let l:dow = wiki#date#get_day_of_week(l:date)
    let l:range = range(1-l:dow, 7-l:dow)
  elseif a:0 == 2
    let l:week = a:1
    let l:year = a:2
    let l:date = l:year . '-01-01'

    let l:dow = wiki#date#get_day_of_week(l:date)
    let l:first_week = wiki#date#get_week(l:date)
    if l:first_week > 1
      let l:first_week = 0
    endif

    let l:ndays = 7*(l:week - l:first_week) - (l:dow - 1)
    let l:range = range(l:ndays, l:ndays+6)
  else
    return []
  endif

  return map(l:range, 's:date_offset(l:date, v:val . '' days'')')
endfunction

" }}}1
function! wiki#date#get_month_name(month) abort " {{{1
  return get(g:wiki_month_names, a:month-1)
endfunction

" }}}1
function! wiki#date#get_month_size(month, year) abort " {{{1
  let l:days_in_month = (a:year % 4 == 0)
        \               && (    (a:year % 100 != 0)
        \                   || ((a:year % 100 == 0) && (a:year % 400 == 0)))
        \ ? [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        \ : [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  return get(l:days_in_month, a:month-1)
endfunction

" }}}1
function! wiki#date#get_month_days(month, year) abort " {{{1
  return map(range(1, wiki#date#get_month_size(a:month, a:year)),
        \ 'printf(''%4d-%02d-%02d'', a:year, a:month, v:val)')
endfunction

" }}}1
function! wiki#date#get_month_decomposed(month, year) abort " {{{1
  let l:n = wiki#date#get_month_size(a:month, a:year)
  let l:days = wiki#date#get_month_days(a:month, a:year)

  let l:dow = wiki#date#get_day_of_week(l:days[0])
  let l:first_monday = l:dow == 1 ? 1 : 9 - l:dow
  let l:first_week = wiki#date#get_week(l:days[l:first_monday-1])

  let l:number_of_weeks = (l:n - l:first_monday + 1)/7
  let l:remaining_days = l:n - 7*l:number_of_weeks - l:first_monday + 1

  let l:days_pre  = l:first_monday   > 1 ? l:days[:l:first_monday-2]  : []
  let l:days_post = l:remaining_days > 0 ? l:days[-l:remaining_days:] : []
  let l:weeks = map(range(l:number_of_weeks),
        \ 'printf(''%4d_w%02d'', a:year, l:first_week + v:val)')

  return l:days_pre + l:weeks + l:days_post
endfunction

" }}}1
function! wiki#date#format_to_regex(format) abort " {{{1
  let l:regex = substitute(a:format, '%[ymdVU]', '\\d\\d', 'g')
  return substitute(l:regex, '%Y', '\\d\\d\\d\\d', '')
endfunction

" }}}1
function! wiki#date#parse_format(date, format) abort " {{{1
  let l:keys = {
        \ 'y' : ['year', 2],
        \ 'Y' : ['year', 4],
        \ 'm' : ['month', 2],
        \ 'd' : ['day', 2],
        \ 'V' : ['week', 2],
        \ 'U' : ['week', 2],
        \}
  let l:rx = '%[' . join(keys(l:keys), '') . ']'

  let l:result = {
      \ 'year': '1970',
      \ 'month': '01',
      \ 'day': '01',
      \}
  let l:date = copy(a:date)
  let l:format = copy(a:format)
  while v:true
    let [l:match, l:pos, l:end] = matchstrpos(l:format, l:rx)
    if l:pos < 0 | break | endif

    let [l:name, l:len] = l:keys[l:match[1]]
    let l:result[l:name] = strpart(l:date, l:pos, l:len)
    let l:date = strpart(l:date, l:pos + l:len)
    let l:format = strpart(l:format, l:end)
  endwhile

  if len(l:result.year) == 2
    let l:result.year = '20' . l:result.year
  endif

  if has_key(l:result, 'week')
    let l:date = printf('%s-01-10', l:result.year)
    let l:dow = wiki#date#get_day_of_week(l:date)
    let l:week = wiki#date#get_week(l:date)
    let l:offset = 7*(l:result.week - l:week) - l:dow + 1
    return s:date_offset(l:date, l:offset . ' days')
  else
    return printf('%4d-%2d-%2d', l:result.year, l:result.month, l:result.day)
  endif
endfunction

" }}}1

"
" Utility functions for running GNU date or similar shell commands
"
function! s:date(date, format) abort " {{{1
  if s:gnu_date
    return systemlist(printf('date +"%s" -d "%s"', a:format, a:date))[0]
  else
    return systemlist(
          \ printf('date -j -f "%Y-%m-%d" "%s" +"%s"', a:date, a:format))[0]
  endif
endfunction

" }}}1
function! s:date_offset(date, offset) abort " {{{1
  if s:gnu_date
    return systemlist(
          \ printf('date +%%F -d "%s +%s"', a:date, a:offset))[0]
  else
    throw 'Not implemented'
  endif
endfunction

" }}}1

let s:gnu_date = match(system('date --version'), 'GNU') >= 0

" vim: fdm=marker sw=2
