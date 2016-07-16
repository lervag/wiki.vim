" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#timesheet#show() " {{{1
  let l:timesheet = s:get_timesheet()

  let l:sum = 0.0
  let l:list = []
  for [l:key, l:vals] in sort(items(l:timesheet))
    if has_key(l:vals, 'hours')
      let l:val = s:sum(l:vals.hours)
      let l:list += [printf('%-20s %6.2f', l:key, l:val)]
      let l:sum += l:val
    endif

    for l:task in filter(keys(l:vals), 'v:val !~# ''hours\|comments''')
      let l:val = s:sum(l:vals[l:task].hours)
      let l:list += [printf('%-20s %6.2f', l:key . ' ' . l:task, l:val)]
      let l:sum += l:val
    endfor
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
python3 <<EOF
from vim import *
import sintefpy

entries = bindeval('s:parse_list()')
print([list(entry) for entry in entries])

EOF
endfunction

" }}}1

function! s:get_timesheet(...) " {{{1
  "
  " Get date, day of week, and list of days in the week
  "
  let l:date = a:0 > 0
        \ ? a:1
        \ : (expand('%:r') =~# '\d\d\d\d-\d\d-\d\d'
        \   ? expand('%:r') : strftime('%F'))
  let l:dow = systemlist('date -d ' . l:date . ' +%u')[0]
  let l:week = systemlist('date -d ' . l:date . ' +%W')[0]
  let l:days = map(range(1-l:dow, 7-l:dow),
        \   'systemlist(''date +%F -d "'
        \               . l:date . ' '' . v:val . '' days"'')[0]')

  let l:timesheet = {}
  for l:dow in range(1,7)
    call s:parse_timesheet(l:dow, l:days[l:dow - 1], l:timesheet)
  endfor

  return l:timesheet
endfunction

" }}}1
function! s:parse_list() " {{{1
  let l:list = []
  for [l:key, l:vals] in items(s:get_timesheet())
    if !has_key(s:table, l:key)
      echo 'Project is not defined in project table'
      echo '-' l:key
      return
    endif
    let l:info = s:table[l:key]
    let l:new = [
            \ s:table[l:key]['number'],
            \ s:table[l:key]['name'],
            \]

    if has_key(l:vals, 'hours')
      if len(l:info.tasks) > 1
        echo 'Task was not uniquely specified for project:' l:key
        for l:name in keys(l:info.tasks)
          echo '-' l:name
        endfor
        return
      endif

      call add(l:list, l:new + values(l:info.tasks)[0]
            \ + l:vals.hours + l:vals.comments)
    endif

    for l:task in filter(keys(l:vals), 'v:val !~# ''hours\|comments''')
      if !has_key(l:info.tasks, l:task)
        echo 'Task "' . l:task . '" is not registered for project:' l:key
        return
      endif
      call add(l:list, l:new + l:info.tasks[l:task]
            \ + l:vals[l:task].hours + l:vals[l:task].comments)
    endfor
  endfor

  return l:list
endfunction

" }}}1
function! s:parse_timesheet(dow, day, timesheet) " {{{1
  let l:file = g:vimwiki.diary . a:day . '.wiki'
  if !filereadable(l:file) | return | endif

  for l:line in readfile(l:file, 20)
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
    let l:parts = split(l:line, '\s\{2,}')
    let l:key = l:parts[0]
    let l:parts = split(l:parts[1], '\s')
    let l:value = str2float(l:parts[0])
    if len(l:parts) > 1
      let l:note = substitute(join(l:parts[1:], ' '), '^(\|)$', '', 'g')
      if l:note =~# '^T\d'
        let l:task = l:note
        unlet l:note
      endif
    endif

    " Create timesheet entry if it does not exist
    if !has_key(a:timesheet, l:key)
      let a:timesheet[l:key] = {}
    endif
    if exists('l:task')
      if !has_key(a:timesheet[l:key], l:task)
        let a:timesheet[l:key][l:task] = {}
      endif
      let l:timesheet = a:timesheet[l:key][l:task]
    else
      let l:timesheet = a:timesheet[l:key]
    endif
    if !has_key(l:timesheet, 'hours')
      let l:timesheet.hours = repeat([0.0], 7)
      let l:timesheet.comments = repeat([''], 7)
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
  let l:sum = 0.0
  for l:n in a:list
    let l:sum += l:n
  endfor
  return l:sum
endfunction

" }}}1

" {{{1 Table of project information

let s:table = {}
let s:table.Diverse = {
      \ 'number' : '99500121-1',
      \ 'name' : 'Intern/GT/Adm. og drift',
      \ 'tasks' : {
      \   'admin' : [9000, 'Administrasjon'],
      \ }
      \}
let s:table.Leiested = {
      \ 'number' : 'L5090023',
      \ 'name' : 'EN leiested: Linux drift (16L72206)',
      \ 'tasks' : {
      \   'drift' : [9005, 'Drift av leiested'],
      \ }
      \}
let s:table.Tekna = {
      \ 'number' : '502000428',
      \ 'name' : 'Intern - Arbeidstakerorganisasjonene  (10A003)',
      \ 'tasks' : {
      \   'tekna' : [10200, 'TEKNA'],
      \ }
      \}
let s:table.Sommerjobb = {
      \ 'number' : '502001249',
      \ 'name' : 'ST/E/Sommerjobbprosjektet 2016',
      \ 'tasks' : {
      \   'admin' : [1000, 'Administrasjon og QA'],
      \ }
      \}
let s:table.3dmf = {
      \ 'number' : '502000610',
      \ 'name' : 'TE_GT/E/3D multifluid flow (I-SIP)',
      \ 'tasks' : {
      \   'modellering' : [1010, 'Modellering'],
      \ }
      \}
let s:table.NanoHX = {
      \ 'number' : '502000504',
      \ 'name' : 'GT/E/NanoHX',
      \ 'tasks' : {
      \   'T0' : [1000, 'Task 0: Project Management and QA'],
      \   'T6' : [1060, 'Task 6: Project development'],
      \   'T8' : [1110, 'Task 8: Code Maintenance'],
      \   'T9' : [1120, 'Task 9: Research tasks'],
      \  }
      \}
let s:table.FerroCool = {
      \ 'number' : '502001365',
      \ 'name' : 'GT/FerroCool',
      \ 'tasks' : {
      \   'T0' : [1000, 'T0: Administrasjon'],
      \   'T1' : [1010, 'T1: Rigg'],
      \   'T4' : [1040, 'T4: Applikasjonsstudie'],
      \  }
      \}
let s:table.RPT = {
      \ 'number' : '502001038',
      \ 'name' : 'GT/KPN/Predict-RPT',
      \ 'tasks' : {
      \   'WP1.1' : [1100, 'WP 1.1: Risk scenario identificatioin'],
      \  }
      \}

" }}}1

" vim: fdm=marker sw=2
