" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#timesheet#get(...) " {{{1
  "
  " Get date, day of week, and list of days in the week
  "
  let l:date = a:0 > 0
        \ ? a:1
        \ : (expand('%:r') =~# '\d\d\d\d-\d\d-\d\d'
        \   ? expand('%:r') : strftime('%F'))
  let l:dow = systemlist('date -d ' . l:date . ' +%u')[0]
  let l:days = map(range(1-l:dow, 7-l:dow),
        \   'systemlist(''date +%F -d "'
        \               . l:date . ' '' . v:val . '' days"'')[0]')

  let l:timesheet = {}
  for l:dow in range(1,7)
    call s:parse_timesheet(l:dow, l:days[l:dow - 1], l:timesheet)
  endfor
  PP l:timesheet
  return l:timesheet
endfunction

" }}}1
function! vimwiki#timesheet#show() " {{{1
  let l:timesheet = vimwiki#timesheet#get()

  let l:sum = 0.0
  let l:list = []
  for [l:key, l:vals] in sort(items(l:timesheet))
    let l:val = s:sum(l:vals)
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
  let l:timesheet = vimwiki#timesheet#get()

  let l:list = []

  for [l:key, l:vals] in sort(items(l:timesheet))
    if !has_key(s:table, l:key)
      echo 'Project is not defined in project table'
      echo '-' l:key
      return
    endif

    let l:new = s:table[
  endfor
endfunction

" }}}1

function! s:parse_timesheet(dow, day, timesheet) " {{{1
  let l:file = g:vimwiki.diary . a:day . '.wiki'
  if !filereadable(l:file) | return | endif

  for l:line in readfile(l:file)
    " Detect start of timesheet info
    if !get(l:, 'start', 0)
      let l:start = (l:line =~# 'Timeoversikt')
      continue
    endif

    " Detect end of timesheet info
    if l:line =~# '^\s*$' | break | endif

    " Skip some lines
    if l:line =~# '^\s*\%(Starta\|Slutta\|-\+\s*$\)' | continue | endif

    " Parse line
    let l:parts = split(l:line, '\s\+')
    let l:key = l:parts[0]
    let l:value = str2float(l:parts[1])
    if len(l:parts) > 2
      let l:parts[2] = substitute(l:parts[2], '^(\|)$', '', 'g')
      if l:parts[2] =~# '^T\d'
        let l:task = l:parts[2]
      else
        let l:note = l:parts[2]
      endif
    endif

    if !has_key(a:timesheet, l:key)
      let a:timesheet[l:key] = {
            \ 'hours' : [0, 0, 0, 0, 0, 0, 0],
            \ 'comments' : ['', '', '', '', '', '', ''],
            \}
    endif

    if exists('l:task')
      if !has_key(a:timesheet[l:key], l:task)
        let a:timesheet[l:key][l:task] = {
              \ 'hours' : [0, 0, 0, 0, 0, 0, 0],
              \ 'comments' : ['', '', '', '', '', '', ''],
              \}
      endif
      let l:timesheet = a:timesheet[l:key][l:task]
    else
      let l:timesheet = a:timesheet[l:key]
    endif

    " Add entry to timesheet
    let l:timesheet.hours[a:dow-1] = l:value
    if exists('l:note')
      let l:timesheet.comments[a:dow-1] = l:note
    endif

    " Clean up before next iteration
    if exists('l:task') | unlet l:task | endif
    if exists('l:note') | unlet l:note | endif
  endfor
endfunction

" }}}1
function! s:sum(list) " {{{1
  let l:sum = 0
  for l:n in a:list
    let l:sum += l:n
  endfor
endfunction

" }}}1

" {{{1 Table of project information

let s:table = {
      \ 'Diverse' : [
      \   '99500121-1',
      \   'Intern/GT/Adm. og drift',
      \   [9000, 'Administrasjon']
      \ ],
      \ 'Leiested' : [
      \   'L5090023',
      \   'EN leiested: Linux drift (16L72206)',
      \   [9005, 'Drift av leiested']
      \ ],
      \ 'Tekna' : [
      \   '502000428',
      \   'Intern - Arbeidstakerorganisasjonene  (10A003)',
      \   [10200, 'TEKNA']
      \ ],
      \ 'Sommerjobb' : [
      \   '502001249',
      \   'ST/E/Sommerjobbprosjektet 2016',
      \   [1000, 'Administrasjon og QA']
      \ ],
      \ '3dmf' : [
      \   '502000610',
      \   'TE_GT/E/3D multifluid flow (I-SIP)',
      \   [1010, 'Modellering']
      \ ],
      \ 'NanoHX' : [
      \   '502000504',
      \   'GT/E/NanoHX',
      \   { 'T0' : [1000, 'Task 0: Project Management and QA'],
      \     'T6' : [1060, 'Task 6: Project development'],
      \     'T8' : [1110, 'Task 8: Code Maintenance'],
      \     'T9' : [1120, 'Task 9: Research tasks'] }
      \ ],
      \ 'FerroCool' : [
      \   '502001365',
      \   'GT/FerroCool',
      \   { 'T0' : [1000, 'T0: Administrasjon'],
      \     'T1' : [1010, 'T1: Rigg'],
      \     'T4' : [1040, 'T4: Applikasjonsstudie'] }
      \ ],
      \ 'RPT' : [
      \   '502001038',
      \   'GT/KPN/Predict-RPT',
      \   [1100, 'WP 1.1: Risk scenario identificatioin'],
      \ ],
      \}

" }}}1

" vim: fdm=marker sw=2
