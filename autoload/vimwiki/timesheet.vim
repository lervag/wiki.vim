" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let s:table = {
      \ '3dmf' : ['...'],
      \ 'Diverse' : ['...'],
      \}

function! vimwiki#timesheet#get() " {{{1
  let l:offset = systemlist('date +%u')[0]

  let l:timesheet = {}

  for l:day in filter(map(
        \    range(1-l:offset, 7-l:offset),
        \   'g:vimwiki.diary . ' .
        \   'systemlist(''date +%F -d "'' . v:val . '' days"'')[0] . ''.wiki'''),
        \ 'filereadable(v:val)')
    call s:add_to_timesheet(l:day, l:timesheet)
  endfor

  let l:sum = 0.0
  let l:list = []
  for [l:key, l:val] in sort(items(l:timesheet))
    let l:list += [printf('%-20s %6.2f', l:key, l:val)]
    let l:sum += l:val
  endfor
  let l:list = sort(l:list)
  let l:list += [repeat('-', 27)]
  let l:list += [printf('%-20s %6.2f', 'Sum', l:sum)]
  let l:list += [repeat('-', 27)]
  for l:entry in l:list
    echo l:entry
  endfor
endfunction

" }}}1
function! vimwiki#timesheet#submit() " {{{1
endfunction

" }}}1

function! s:add_to_timesheet(day, timesheet) " {{{1
  for l:line in readfile(a:day)
    "
    " Detect start of timesheet info
    "
    if !get(l:, 'start', 0)
      let l:start = (l:line =~# 'Timeoversikt')
      continue
    endif

    "
    " Detect end of timesheet info
    "
    if l:line =~# '^\s*$' | break | endif

    "
    " Skip some lines
    "
    if l:line =~# '^\s*\%(Starta\|Slutta\|-\+\s*$\)' | continue | endif

    let l:parts = split(l:line, '\s\+')

    "
    " Parse value
    "
    let l:value = str2float(l:parts[1])
    if l:value == 0.0 | continue | endif

    "
    " Parse key
    "
    let l:key = l:parts[0]
          \ . (len(l:parts) > 2 ? ' ' . l:parts[2] : '')

    "
    " Add to timesheet
    "
    let a:timesheet[l:key] = get(a:timesheet, l:key, 0.0) + l:value
  endfor
endfunction

" }}}1

" vim: fdm=marker sw=2
