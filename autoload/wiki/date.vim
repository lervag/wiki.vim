" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

"
" Get info for given date
"
function! wiki#date#get_week(date) " {{{1
  return systemlist('date +%W -d ' . a:date)[0]
endfunction

" }}}1
function! wiki#date#get_day_of_week(date) " {{{1
  return systemlist('date +%u -d ' . a:date)[0]
endfunction

" }}}1

"
" More complex parsers
"
function! wiki#date#get_next_weekday(date) " {{{1
  let l:day = systemlist('date +%F -d "' . a:date . ' +1 day"')[0]
  while wiki#date#get_day_of_week(l:day) > 5
    let l:day = systemlist('date +%F -d "' . l:day . ' +1 day"')[0]
  endwhile
  return l:day
endfunction

" }}}1
function! wiki#date#get_week_dates(...) " {{{1
  "
  " Argument: Either a single date string, or a week number and a year
  "
  if a:0 == 1
    let l:date = a:1
    let l:dow = systemlist('date +"%u" -d ' . l:date)[0]
    return map(range(1-l:dow,7-l:dow),
          \ 'systemlist(''date +%F -d "'
          \             . l:date . ' '' . v:val . '' days"'')[0]')
  elseif a:0 == 2
    let l:week = a:1
    let l:year = a:2
    let l:date_first = l:year . '-01-01'

    let [l:first_week, l:dow] =
          \ split(systemlist('date +"%V %u" -d ' . l:date_first)[0], ' ')

    let l:first_monday = (9 - l:dow) % 7
    let l:first_week = (l:first_week % 52) + (l:first_monday > 1)
    let l:ndays = 7*(l:week - l:first_week + 1) - (l:dow - 1)

    return map(range(l:ndays, l:ndays+6),
          \ 'systemlist(''date +%F -d "'
          \             . l:date_first . ' '' . v:val . '' days"'')[0]')
  else
    return []
  endif
endfunction

" }}}1
function! wiki#date#get_month_name(month) " {{{1
  return get([
        \ 'januar',
        \ 'februar',
        \ 'mars',
        \ 'april',
        \ 'mai',
        \ 'juni',
        \ 'juli',
        \ 'august',
        \ 'september',
        \ 'oktober',
        \ 'november',
        \ 'desember'
        \], a:month-1)
endfunction

" }}}1
function! wiki#date#get_month_size(month, year) " {{{1
  let l:days_in_month = (a:year % 4 == 0)
        \               && (    (a:year % 100 != 0)
        \                   || ((a:year % 100 == 0) && (a:year % 400 == 0)))
        \ ? [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
        \ : [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

  return get(l:days_in_month, a:month-1)
endfunction

" }}}1
function! wiki#date#get_month_days(month, year) " {{{1
  return map(range(1, wiki#date#get_month_size(a:month, a:year)),
        \ 'printf(''%4d-%02d-%02d'', a:year, a:month, v:val)')
endfunction

" }}}1
function! wiki#date#get_month_decomposed(month, year) " {{{1
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

" vim: fdm=marker sw=2
