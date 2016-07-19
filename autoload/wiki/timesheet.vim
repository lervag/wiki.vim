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
  for [l:key, l:vals] in items(l:timesheet)
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
  echohl None

  echo ''
  if input('Submit to Maconomy? [y/N]') =~# '^y'
    call wiki#timesheet#submit()
  endif
endfunction

" }}}1
function! wiki#timesheet#submit() " {{{1
python3 <<EOF
from vim import *
import sintefpy

lists = bindeval('s:create_maconomy_lists()')
print([list(entry) for entry in lists])

EOF
endfunction

" }}}1
function! wiki#timesheet#get_registered_projects() " {{{1
  return keys(s:table)
endfunction

" }}}1

function! s:create_maconomy_lists() " {{{1
  let l:list = []
  for [l:key, l:vals] in items(s:parse_timesheet_week())
    if !has_key(s:table, l:key)
      echo 'Project is not defined in project table:' l:key
      return []
    endif
    let l:info = s:table[l:key]
    let l:new = [
            \ s:table[l:key]['number'],
            \ s:table[l:key]['name'],
            \]

    if has_key(l:vals, 'hours')
      if len(l:info.tasks) > 1
        echo 'Task was not uniquely specified for project:' l:key
        echo 'Registered tasks are:'
        for [l:name, l:task] in items(l:info.tasks)
          echo '-' l:name  '(' . l:task[0] . ')'
        endfor
        return []
      endif

      call add(l:list, l:new + values(l:info.tasks)[0]
            \ + l:vals.hours + l:vals.note)
    endif

    for l:task in filter(keys(l:vals), 'v:val !~# ''hours\|note''')
      if !has_key(l:info.tasks, l:task)
        echo 'Task "' . l:task . '" is not registered for project:' l:key
        echo 'Registered tasks are:'
        for [l:name, l:task] in items(l:info.tasks)
          echo '-' l:name  '(' . l:task[0] . ')'
        endfor
        return []
      endif
      call add(l:list, l:new + l:info.tasks[l:task]
            \ + l:vals[l:task].hours + l:vals[l:task].note)
    endfor
  endfor

  return l:list
endfunction

" }}}1

function! s:parse_timesheet_week(...) " {{{1
  let l:date = a:0 > 0
        \ ? a:1
        \ : expand('%:r') =~# '\d\d\d\d-\d\d-\d\d'
        \   ? expand('%:r')
        \   : strftime('%F')

  let l:days = wiki#date#get_week_dates(wiki#date#get_week(l:date), l:date[:3])

  let l:timesheet = {}
  for l:dow in range(1,7)
    call s:parse_timesheet_day(l:dow, l:days[l:dow - 1], l:timesheet)
  endfor

  return l:timesheet
endfunction

" }}}1
function! s:parse_timesheet_day(dow, day, timesheet) " {{{1
  let l:file = g:wiki.diary . a:day . '.wiki'
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

"
" Better data structure?
"
function! s:parse_timesheet_week_new(...) " {{{1
  let l:date = a:0 > 0
        \ ? a:1
        \ : expand('%:r') =~# '\d\d\d\d-\d\d-\d\d'
        \   ? expand('%:r')
        \   : strftime('%F')

  let l:days = wiki#date#get_week_dates(wiki#date#get_week(l:date), l:date[:3])

  "
  " Create timesheet dictionary
  "
  let l:timesheet = {
        \ 'week' : systemlist('date +%W -d ' . l:date)[0],
        \ 'entries' : [],
        \}
  for l:dow in range(1,7)
    let l:
          \ 'projects' : s:parse_timesheet_day(l:days[l:dow-1])
    call add(l:timesheet.entries, {
          \ 'dow' : l:days[l:dow-1],
          \ 'date' : l:dow,
          \ 'projects' : s:parse_timesheet_day(l:days[l:dow-1])
          \})

  return l:timesheet
endfunction

" }}}1
function! s:parse_timesheet_day_new(day) " {{{1
  let l:file = g:wiki.diary . a:day . '.wiki'
  if !filereadable(l:file) | return | endif

  let l:entry = {}

  for l:line in readfile(l:file, 20)
    if !get(l:, 'start', 0)
      let l:start = (l:line =~# 'Timeoversikt')
      continue
    endif
    if l:line =~# '^\s*$' | break | endif
    if l:line =~# '^\s*\%(Starta\|Slutta\|-\+\s*$\)' | continue | endif

    let l:parts = split(l:line, '\s\{2,}')
    let l:key = l:parts[0]
    let l:entry[l:key] = {}

    let l:parts = split(l:parts[1], '\s')
    let l:value = str2float(l:parts[0])
    if len(l:parts) > 1
      let l:string = substitute(join(l:parts[1:], ' '), '^(\|)$', '', 'g')
      if l:string =~# '^T\d'
        let l:entry[l:key][l:string] = { 'hours' : l:value }
        continue
      endif
      let l:entry[l:key].note = l:string
    endif
    let l:entry[l:key].hours = l:value
  endfor

  return l:entry
endfunction

" }}}1

" vim: fdm=marker sw=2
