" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#timesheet#show() " {{{1
  let l:timesheet = s:parse_timesheet_week()

  let l:titles = ['Projects',
        \ 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Sum']

  let l:projects = []
  for l:key in s:table_ordered
    if !has_key(l:timesheet, l:key) | continue | endif
    let l:vals = l:timesheet[l:key]
    if type(l:vals) != type({}) | continue | endif

    if has_key(l:vals, 'hours')
      call add(l:projects, [l:key] + l:vals.hours + [s:sum(l:vals.hours)])
    endif

    for l:task in filter(keys(l:vals), 'v:val !~# ''hours\|note''')
      call add(l:projects, [l:key . ' ' . l:task]
            \ + l:vals[l:task].hours + [s:sum(l:vals[l:task].hours)])
    endfor
  endfor

  let l:sums = ['Sum'] + repeat([0.0], 8)
  for l:proj in l:projects
    for l:i in range(1,8)
      let l:sums[i] += l:proj[i]
    endfor
  endfor

  if l:sums[-1] == 0.0
    echo 'No hours registered'
    return
  endif

  if l:sums[7] == 0.0
    call remove(l:sums, 7)
    call remove(l:titles, 7)
    for l:proj in l:projects
      call remove(l:proj, 7)
    endfor
  endif

  if l:sums[6] == 0.0
    call remove(l:sums, 6)
    call remove(l:titles, 6)
    for l:proj in l:projects
      call remove(l:proj, 6)
    endfor
  endif

  echohl ModeMsg
  echo 'Date:' l:timesheet.date
  echo printf("Week: %02d%54s\n\n", l:timesheet.week,
        \ l:timesheet.dates[0] . ' -- ' . l:timesheet.dates[-1])
  echohl Title
  echo call('printf', ['%-20s' . repeat('%7s', len(l:sums) - 1)] + l:titles)
  echohl ModeMsg
  echo repeat('-', 20 + 7*(len(l:sums) - 1))
  echohl None
  for l:proj in l:projects
    let l:fmt = ''
    for l:i in range(1, len(l:proj)-1)
      if l:proj[l:i] == 0.0
        let l:proj[l:i] = ''
        let l:fmt .= '%7s'
      else
        let l:fmt .= '%7.2f'
      endif
    endfor
    echohl ModeMsg
    echo printf('%-20s', l:proj[0])
    echohl ModeMsg
    echohl Number
    echon call('printf', [l:fmt] + l:proj[1:])
    echohl None
  endfor
  echohl ModeMsg
  echo repeat('-', 20 + 7*(len(l:sums) - 1))
  echohl Title
  echo call('printf', ['%-20s' . repeat('%7.2f', len(l:sums) - 1)] + l:sums)
  echohl ModeMsg
  echo repeat('-', 20 + 7*(len(l:sums) - 1))

  let l:reply = input("\nSubmit to Maconomy [y/N]? ")
  echohl None
  if l:reply =~# '^y'
    echo "\nAccessing Maconomy"
    call wiki#timesheet#submit(l:timesheet)
  endif
endfunction

" }}}1
function! wiki#timesheet#submit(...) " {{{1
  let l:timesheet = a:0 > 0 ? a:1 : s:parse_timesheet_week()
  let l:lines = s:get_maconomy_lines(l:timesheet)

python3 <<EOF
from vim import *
import datetime

from sintefpy.credentials import get_credentials
from sintefpy.maconomy    import MaconomySession
from sintefpy.timesheet   import Timesheet, TimesheetLine

lines = eval('l:lines')

user, pw = get_credentials()
with MaconomySession(username='SINTEFGRP\\' + user, password=pw) as ms:
    ts = Timesheet(ms)
    ts.change_date(datetime.datetime.now())
    ts.open_if()
    ts.clear_all_lines()

    for p in lines:
        print('- Submitting: {projname} ({taskname})'.format(**p))
        lineno = len(ts.timesheettable)
        ts.insert_line()
        ts.fill_line(lineno, TimesheetLine(p['projnr'], p['tasknr'], p['hours']))

    ts.submit()
EOF
endfunction

" }}}1
function! wiki#timesheet#get_registered_projects() " {{{1
  return s:table_ordered
endfunction

" }}}1

function! s:get_maconomy_lines(timesheet) " {{{1
  let l:list = []
  for l:key in s:table_ordered
    if !has_key(a:timesheet, l:key) | continue | endif
    let l:vals = l:timesheet[l:key]
    if type(l:vals) != type({}) | continue | endif

    if !has_key(s:table, l:key)
      echo 'Project is not defined in project table:' l:key
      return []
    endif
    let l:info = s:table[l:key]
    let l:new = {
          \ 'projnr' : s:table[l:key]['number'],
          \ 'projname' : s:table[l:key]['name'],
          \}

    if has_key(l:vals, 'hours')
      if has_key(l:info, 'default')
        call add(l:list, extend(copy(l:new), {
              \ 'tasknr' : l:info.tasks[l:info.default],
              \ 'taskname' : l:info.default,
              \ 'hours' : l:vals.hours,
              \ 'notes' : l:vals.note,
              \}))
      else
        if len(l:info.tasks) > 1
          echo 'Task was not uniquely specified for project:' l:key
          echo 'Registered tasks are:'
          for [l:name, l:task] in items(l:info.tasks)
            echo '-' l:name  '(' . l:task . ')'
          endfor
          return []
        endif

        call add(l:list, extend(copy(l:new), {
              \ 'tasknr' : values(l:info.tasks)[0],
              \ 'taskname' : keys(l:info.tasks)[0],
              \ 'hours' : l:vals.hours,
              \ 'notes' : l:vals.note,
              \}))
      endif
    endif

    for l:task in filter(keys(l:vals), 'v:val !~# ''hours\|note''')
      if !has_key(l:info.tasks, l:task)
        echo 'Task "' . l:task . '" is not registered for project:' l:key
        echo 'Registered tasks are:'
        for [l:name, l:task] in items(l:info.tasks)
          echo '-' l:name  '(' . l:task . ')'
        endfor
        return []
      endif
      call add(l:list, extend(copy(l:new), {
            \ 'tasknr' : l:info.tasks[l:task],
            \ 'taskname' : l:task,
            \ 'hours' : l:vals[l:task].hours,
            \ 'notes' : l:vals[l:task].note,
            \}))
    endfor
  endfor

  return l:list
endfunction

" }}}1

function! s:parse_timesheet_week() " {{{1
  if expand('%:t:r') =~# '\d\d\d\d-\d\d-\d\d'
    let l:date = expand('%:t:r')
    let l:days = wiki#date#get_week_dates(l:date)
  else
    let l:date = strftime('%F')
    let l:days = wiki#date#get_week_dates(strftime('%V'), strftime('%Y'))
  endif

  let l:timesheet = {
        \ 'week' : wiki#date#get_week(l:days[0]),
        \ 'dates' : l:days,
        \ 'date' : l:date,
        \}
  for l:dow in range(7)
    call s:parse_timesheet_day(l:dow+1, l:days[l:dow], l:timesheet)
  endfor

  return l:timesheet
endfunction

" }}}1
function! s:parse_timesheet_day(dow, day, timesheet) " {{{1
  let l:file = g:wiki.journal . a:day . '.wiki'
  if !filereadable(l:file) | return | endif

  let l:regex = '^\v\s*(\| )?(' . join(keys(s:table), '|') . ').*\d\.\d'
  let l:lines = filter(readfile(l:file, 15), 'v:val =~# l:regex')
  if empty(l:lines) | return | endif

  let l:type = l:lines[0] =~# '^\s*|' ? 'new' : 'old'
  call s:parse_timesheet_lines_{l:type}(l:lines, a:dow, a:timesheet)
endfunction

" }}}1
function! s:parse_timesheet_lines_new(lines, dow, timesheet) " {{{1
  for l:line in a:lines
    let [l:key, l:task, l:hours, l:note] = split(l:line, '\s*|\s*')
    call s:parse_timesheet_add_line(l:key,
          \ l:task, str2float(l:hours), l:note, a:dow, a:timesheet)
  endfor
endfunction

" }}}1
function! s:parse_timesheet_lines_old(lines, dow, timesheet) " {{{1
  for l:line in a:lines
    let l:parts1 = split(l:line, '\s\{2,}')
    let l:parts2 = split(l:parts1[1], '\s')

    let l:key = l:parts1[0]
    let l:hours = str2float(l:parts2[0])
    let l:note = ''
    let l:task = ''
    if len(l:parts2) > 1
      let l:string = substitute(join(l:parts2[1:], ' '), '^(\|)$', '', 'g')
      if l:string =~# '^T\d'
        let l:task = l:string
      else
        let l:note = l:string
      endif
    endif

    call s:parse_timesheet_add_line(l:key, l:task, l:hours, l:note, a:dow, a:timesheet)
  endfor
endfunction

" }}}1
function! s:parse_timesheet_add_line(key, task, hours, note, dow, timesheet) " {{{1
  if empty(a:key) || a:hours == 0.0 | return | endif

  if !has_key(a:timesheet, a:key)
    let a:timesheet[a:key] = {}
  endif

  if empty(a:task)
    let l:timesheet = a:timesheet[a:key]
  else
    if !has_key(a:timesheet[a:key], a:task)
      let a:timesheet[a:key][a:task] = {}
    endif
    let l:timesheet = a:timesheet[a:key][a:task]
  endif

  if !has_key(l:timesheet, 'hours')
    let l:timesheet.hours = repeat([0.0], 7)
    let l:timesheet.note = repeat([''], 7)
  endif

  let l:timesheet.hours[a:dow-1] = a:hours
  if !empty('a:note')
    let l:timesheet.note[a:dow-1] = a:note
  endif
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

let s:table_ordered = [
      \ 'Borte',
      \ 'Diverse',
      \ 'Leiested',
      \ 'Tekna',
      \ 'Sommerjobb',
      \ '3dmf',
      \ 'NanoHX',
      \ 'FerroCool',
      \ 'RPT',
      \]

let s:table.Borte = {
      \ 'number' : '98500100',
      \ 'name' : 'Fravær/Permisjon',
      \ 'tasks' : {
      \   'Omsorg' : 9404,
      \ }
      \}

let s:table.Diverse = {
      \ 'number' : '99500121-1',
      \ 'name' : 'Intern',
      \ 'tasks' : {
      \   'admin' : 9000,
      \ }
      \}

let s:table.Leiested = {
      \ 'number' : 'L5090023',
      \ 'name' : 'Leiested (linux drift)',
      \ 'tasks' : {
      \   'drift' : 9005,
      \ }
      \}

let s:table.Tekna = {
      \ 'number' : '502000428',
      \ 'name' : 'ATOer',
      \ 'tasks' : {
      \   'tekna' : 10200,
      \ }
      \}

let s:table.Sommerjobb = {
      \ 'number' : '502001249',
      \ 'name' : 'Sommerjobbprosjektet 2016',
      \ 'tasks' : {
      \   'admin' : 1000,
      \ }
      \}

let s:table.3dmf = {
      \ 'number' : '502000610',
      \ 'name' : '3dmf',
      \ 'tasks' : {
      \   'modellering' : 1010,
      \ }
      \}

let s:table.NanoHX = {
      \ 'number' : '502000504',
      \ 'name' : 'NanoHX',
      \ 'tasks' : {
      \   'T0' : 1000,
      \   'T6' : 1060,
      \   'T8' : 1110,
      \   'T9' : 1120,
      \  }
      \}

let s:table.FerroCool = {
      \ 'number' : '502001365',
      \ 'name' : 'FerroCool',
      \ 'tasks' : {
      \   'T0' : 1000,
      \   'T1' : 1010,
      \   'T4' : 1040,
      \  }
      \}

let s:table.RPT = {
      \ 'number' : '502001038',
      \ 'name' : 'Predict-RPT',
      \ 'default' : 'WP1.1',
      \ 'tasks' : {
      \   'WP1.1' : 1100,
      \   'WP2.1' : 1100,
      \  }
      \}

" }}}1

" vim: fdm=marker sw=2
