" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#date#get_day_of_week(date) abort " {{{1
  return strftime('%u', wiki#date#strptime#isodate(a:date))
endfunction

" }}}1
function! wiki#date#get_week(date) abort " {{{1
  return strftime('%V', wiki#date#strptime#isodate(a:date))
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
    let l:date = wiki#date#get_week_first_date(a:1, a:2)
    let l:range = range(0, 6)
  else
    return []
  endif

  return map(l:range, { _, x -> s:date_offset(l:date, x) })
endfunction

" }}}1
function! wiki#date#get_week_first_date(week, year) abort " {{{1
  let l:date_first = a:year . '-01-01'
  let l:dow = wiki#date#get_day_of_week(l:date_first)
  let l:first_week = wiki#date#get_week(l:date_first)
  if l:first_week > 1
    let l:first_week = 0
  endif

  let l:offset_days = 7*(a:week - l:first_week) - l:dow + 1
  return s:date_offset(l:date_first, l:offset_days)
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
  return map(
        \ range(1, wiki#date#get_month_size(a:month, a:year)),
        \ { _, x -> printf('%4d-%02d-%02d', a:year, a:month,x) }
        \)
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
  let l:weeks = map(
        \ range(l:number_of_weeks),
        \ { _, x -> printf('%4d-w%02d', a:year, l:first_week + x) }
        \)

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
        \ 'V' : ['week_iso', 2],
        \ 'U' : ['week', 2],
        \}
  let l:rx = '%[' . join(keys(l:keys), '') . ']'

  let l:result = {}
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

  return l:result
endfunction

" }}}1

function! wiki#date#strptime(format, timestring) abort " {{{1
  " This function currently supports the following fields in the format string:
  " * %Y  year  (2 digits)
  " * %Y  year  (4 digits)
  " * %m  month (00..12)
  " * %d  day   (01..31)
  " * %V        (week number, Monday first)
  " * %U        (week number, Sunday first)  [TODO: Not supported yet!)]
  let l:dd = wiki#date#parse_format(a:timestring, a:format)

  if !has_key(l:dd, 'year') | return 0 | endif

  if has_key(l:dd, 'week_iso')
    return wiki#date#strptime#isoweek(l:dd.year, l:dd.week_iso)
  endif

  if !has_key(l:dd, 'month') | return 0 | endif

  let l:date = printf('%s-%s-%s', l:dd.year, l:dd.month, get(l:dd, 'day', 1))
  return wiki#date#strptime#isodate(l:date)
endfunction

" }}}1

function! s:date_offset(date, offset_days) abort " {{{1
  if a:offset_days == 0 | return a:date | endif

  let l:timestamp = wiki#date#strptime#isodate(a:date)
  let l:timestamp += 86400*a:offset_days
  return strftime('%F', l:timestamp)
endfunction

" }}}1
