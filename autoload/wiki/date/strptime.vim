" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#date#strptime#isodate(timestring) abort " {{{1
  return s:has_strptime
        \ ? strptime('%Y-%m-%d', a:timestring)
        \ : wiki#date#strptime#isodate_implicit(a:timestring)
endfunction

let s:has_strptime
      \ = exists('*strptime') && strptime('%Y-%m-%d', '2000-01-01') > 0

" }}}1
function! wiki#date#strptime#isodate_implicit(date_target) abort " {{{1
  if a:date_target !~# '^\d\d\d\d-\d\d-\d\d$'
    call wiki#log#error('Argument error: ' . a:date_target)
    return 0
  endif

  let l:year = a:date_target[:3]
  let l:month = a:date_target[5:6]
  let l:day = a:date_target[8:]

  " Add hour for target to get more precise results
  let l:date_target = a:date_target . '-00'

  let l:count = 0
  let l:current = 1666562400
  while l:count < 100
    let l:count += 1

    let l:date = strftime('%Y-%m-%d-%H', l:current)
    if l:date ==# l:date_target | return l:current | endif

    let l:current += 31536000*(l:year - l:date[:3])
    let l:current += 2592000*(l:month - l:date[5:6])
    let l:current += 86400*(l:day - l:date[8:9])
    let l:current += 3600*l:date[10:]
  endwhile

  return 0
endfunction

" }}}1
function! wiki#date#strptime#isoweek(year, week_target) abort " {{{1
  " There's no easy way to get timestamp from the weekly format, but it is easy
  " to format a date into a weekly format. So we can get a valid timestamp by
  " inverting the problem.

  let l:start = wiki#date#strptime#isodate(a:year . '-01-01')
  let l:end = wiki#date#strptime#isodate(a:year . '-12-31')

  let l:week_start = strftime('%V', l:start)
  if l:week_start > 1
    let l:week_start = 0
  endif
  let l:week_end = strftime('%V', l:end)
  if l:week_end <= 1
    let l:week_end += 52
  endif
  if empty(a:week_target)
        \ || a:week_target < l:week_start
        \ || a:week_target > l:week_end
    return 0
  endif

  let l:delta = (l:end - l:start)/53
  let l:timestamp = l:start + a:week_target*l:delta
  let l:iters = 0
  while l:iters < 10
    let l:iters += 1
    let l:week_current = strftime('%V', l:timestamp)
    if l:week_current == a:week_target
      return l:timestamp
    elseif l:week_current < a:week_target
      let l:timestamp += l:delta
    else
      let l:timestamp -= l:delta
    endif
  endwhile

  return 0
endfunction

" }}}1
