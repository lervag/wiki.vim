" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

"
" Get info for given date
"
function! wiki#date#format(date, format) abort " {{{1
  return systemlist(printf('date +"%s" -d "%s"', a:format, a:date))[0]

  " Probably better on BSD
  return systemlist(
        \ printf('date -j -f "%Y-%m-%d" "%s" +"%s"', a:format, a:date))[0]
endfunction

" }}}1
function! wiki#date#get_week(date) abort " {{{1
  " This should work on Linux machines
  let l:week = systemlist('date +%V -d ' . a:date)[0]
  if l:week =~# '\d\+' | return l:week | endif

  " This should work on BSD
  let l:week = systemlist("date -j -f '%Y-%m-%d' " . a:date . ' +%V')[0]
  if l:week =~# '\d\+' | return l:week | endif

  " This number sort of screams "something is wrong"
  return 55
endfunction

" }}}1
function! wiki#date#get_day_of_week(date) abort " {{{1
  return systemlist('date +%u -d ' . a:date)[0]
endfunction

" }}}1

"
" Utility functions
"
function! wiki#date#frmt_to_regex(frmt) abort " {{{1
  let l:regex = substitute(a:frmt, '%[ymdVU]', '\\d\\d', 'g')
  return substitute(l:regex, '%Y', '\\d\\d\\d\\d', '')
endfunction

" }}}1
function! wiki#date#parse_frmt(date, frmt) abort " {{{1
  let l:keys = {
        \ 'y' : ['year', 2],
        \ 'Y' : ['year', 4],
        \ 'm' : ['month', 2],
        \ 'd' : ['day', 2],
        \ 'V' : ['week', 2],
        \ 'U' : ['week', 2],
        \}
  let l:rx = '%[' . join(keys(l:keys), '') . ']'

  let l:result = deepcopy(s:date)
  let l:date = copy(a:date)
  let l:frmt = copy(a:frmt)
  while v:true
    let [l:match, l:pos, l:end] = matchstrpos(l:frmt, l:rx)
    if l:pos < 0 | break | endif

    let [l:name, l:len] = l:keys[l:match[1]]
    let l:result[l:name] = strpart(l:date, l:pos, l:len)
    let l:date = strpart(l:date, l:pos + l:len)
    let l:frmt = strpart(l:frmt, l:end)
  endwhile

  return l:result.init()
endfunction

" }}}1

let s:date = {
      \ 'year': '1970',
      \ 'month': '01',
      \ 'day': '01',
      \}
function! s:date.init() abort dict " {{{1
  unlet self.init

  if len(self.year) == 2
    let self.year = '20' . self.year
  endif

  if has_key(self, 'week')
    let l:date = printf('%s-01-10', self.year)
    let l:dow = wiki#date#get_day_of_week(l:date)
    let l:week = wiki#date#get_week(l:date)
    let l:offset = 7*(self.week - l:week) - l:dow + 1
    let l:date = systemlist(
          \ printf('date +%%F -d "%s +%s days"', l:date, l:offset))[0]

    let self.month = l:date[5:6]
    let self.day = l:date[8:9]
  else
    let self.week = wiki#date#get_week(self.to_iso())
  endif

  return self
endfunction

" }}}1
function! s:date.next(freq) abort dict " {{{1
  let l:new_date = systemlist(
        \ printf('date +%%F-%V -d "%s +1 %s"', self.to_iso(), a:freq))[0]

  let self.year = l:new_date[0:3]
  let self.month = l:new_date[5:6]
  let self.day = l:new_date[8:9]
  let self.week = l:new_date[11:12]

  return self
endfunction

" }}}1
function! s:date.to_iso() abort dict " {{{1
  return printf('%4d-%2d-%2d', self.year, self.month, self.day)
endfunction

" }}}1

"
" More complex parsers
"
function! wiki#date#get_next_weekday(date) abort " {{{1
  let l:day = systemlist('date +%F -d "' . a:date . ' +1 day"')[0]
  while wiki#date#get_day_of_week(l:day) > 5
    let l:day = systemlist('date +%F -d "' . l:day . ' +1 day"')[0]
  endwhile
  return l:day
endfunction

" }}}1
function! wiki#date#get_week_dates(...) abort " {{{1
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
    if l:first_week > 1
      let l:first_week = 0
    endif

    let l:ndays = 7*(l:week - l:first_week) - (l:dow - 1)

    return map(range(l:ndays, l:ndays+6),
          \ 'systemlist(''date +%F -d "'
          \             . l:date_first . ' '' . v:val . '' days"'')[0]')
  else
    return []
  endif
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

" vim: fdm=marker sw=2
