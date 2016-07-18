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
  let l:next_day = wiki#date#get_next_weekday(expand('%:t:r'))

  let l:next_entry = g:wiki.diary . l:next_day . '.wiki'
  if !filereadable(l:next_entry)
    execute 'write' l:next_entry
  endif

  call wiki#url#parse('diary:' . l:next_day).open()
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
  let l:year = l:date[:3]
  let l:week = wiki#date#get_week(l:date)
  call wiki#url#parse('diary:' . l:year . '_w' . l:week).open()

  if !filereadable(expand('%'))
    let l:days = filter(wiki#date#get_dates_in_week(l:date),
          \ 'filereadable(v:val . ''.wiki'')')

    let l:lines = ['# Samandrag veke ' . l:week . ', ' . l:year]
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
  let l:year = l:date[:3]
  let l:month = wiki#date#get_month(l:date)
  call wiki#url#parse('diary:' . l:year . '_m' . l:month).open()

  if !filereadable(expand('%'))
    let [l:pre, l:weeks, l:post] = wiki#date#decompose_month(l:month, l:year)

    let l:links = map(
          \ copy(l:pre)
          \ + map(l:weeks, 'l:year . ''_w'' . v:val') + copy(l:post),
          \ '''diary:'' . v:val')

    call append(0, [
          \ '# Samandrag frå ' . wiki#date#get_month_name(l:month) . ' ' . l:date[:3],
          \ ''
          \] + l:links)
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
