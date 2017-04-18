" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#timesheet#show() abort " {{{1
  let l:timesheet = s:timesheet.new()
  let l:table = l:timesheet.tableize()

  " Remove weekend if nothing is registered
  for l:i in range(8, 7, -1)
    if l:table.sums[l:i] > 0.0 | break | endif

    call remove(l:table.sums, l:i)
    call remove(l:table.titles, l:i)
    for l:row in l:table.rows
      call remove(l:row, l:i)
    endfor
  endfor

  let l:title_frmt = '%-30s%-6s' . repeat('%7s', len(l:table.sums) - 2)
  let l:line = repeat('-', 39 + 7*(len(l:table.sums) - 2))

  echohl ModeMsg
  echo printf("Week: %02d (%s)\n\n", l:timesheet.week,
        \ l:timesheet.dates[0] . ' -- ' . l:timesheet.dates[-1])
  echohl Title
  echo call('printf', [l:title_frmt] + l:table.titles)
  echohl ModeMsg
  echo l:line
  for l:row in l:table.rows
    echohl ModeMsg
    echo printf('%-30s%-6s', l:row[0], l:row[1])
    echohl Number

    let l:fmt = ''
    for l:i in range(2, len(l:row)-1)
      if l:row[l:i] == 0.0
        let l:row[l:i] = ''
        let l:fmt .= '%7s'
      else
        let l:fmt .= '%7.2f'
      endif
    endfor
    echon call('printf', [l:fmt] + l:row[2:])
  endfor
  echohl ModeMsg
  echo l:line
  echohl Title
  echo call('printf', [l:title_frmt] + l:table.sums)
  echohl ModeMsg
  echo l:line

  let l:reply = input("\nSubmit to Maconomy [y/N]? ")
  echohl None
  echon "\n"
  if l:reply =~# '^y'
    call wiki#timesheet#submit(l:timesheet)
  else
    redraw!
  endif
endfunction

" }}}1
function! wiki#timesheet#submit(...) abort " {{{1
  let l:timesheet = a:0 > 0 ? a:1 : s:timesheet.new()
  let l:lines = l:timesheet.maconomize()
  if empty(l:lines) | return | endif

  python3 <<EOF
import vim
import sys
sys.modules['keyring'] = 1
sys.setrecursionlimit(2000)

from sintefpy.credentials import get_credentials
from sintefpy.maconomy import Session, Timesheet

print('Connecting to Maconomy')
user, pw = get_credentials()
with Session(user, password=pw) as ms:
    print('- Opening timesheet')
    ts = Timesheet.from_session(ms)
    ts.change_date(vim.eval('l:timesheet.date'))
    ts.open()
    print('- Submitting hours')
    ts.clear_all_hours()
    for line in vim.eval('l:lines'):
        info = '  - ' + line.get('projname', '--')
        task = line.get('taskname', '')
        if task:
            info += ' [' + task + ']'
        print(info)
        ts.fill_line(line)
    ts.submit()
    print('- Finished')
EOF
endfunction

" }}}1
function! wiki#timesheet#get_registered_projects() abort " {{{1
  return s:table_ordered
endfunction

" }}}1

let s:timesheet = {}
function! s:timesheet.new() abort dict " {{{1
  let l:t = deepcopy(self)

  if expand('%:t:r') =~# '\d\d\d\d-\d\d-\d\d'
    let l:t.date = expand('%:t:r')
    let l:t.dates = wiki#date#get_week_dates(l:t.date)
  else
    let l:t.date = strftime('%F')
    let l:t.dates = wiki#date#get_week_dates(strftime('%V'), strftime('%Y'))
  endif

  let l:t.week = wiki#date#get_week(l:t.dates[0])
  let l:t.data = {}

  for l:dow in range(1,7)
    call l:t.parse_day(l:dow)
  endfor

  " Create ordered list of data
  let l:t.data_ordered = []
  let l:data = deepcopy(l:t.data)
  for l:k in s:table_ordered
    if has_key(l:data, l:k)
      call add(l:t.data_ordered, remove(l:data, l:k))
    endif
  endfor
  call extend(l:t.data_ordered, values(l:data))

  unlet l:t.new
  unlet l:t.parse_day
  unlet l:t.add

  return l:t
endfunction

" }}}1
function! s:timesheet.parse_day(dow) abort dict " {{{1
  let l:file = g:wiki.journal . self.dates[a:dow-1] . '.wiki'
  if !filereadable(l:file) | return | endif

  let l:lines = readfile(l:file, '', 50)
  let l:lnum = 0
  let l:lnum_start = 0
  let l:lnum_end = len(l:lines)
  for l:lnum in range(l:lnum_end)
    if l:lines[l:lnum] =~# '^| Prosjekt.*Timer'
      let l:lnum_start = l:lnum + 2
      break
    endif
  endfor

  for l:lnum in range(l:lnum_start, l:lnum_end-1)
    if l:lines[l:lnum] =~# '^\s*$'
      let l:lnum_end = l:lnum - 2
      break
    endif
  endfor

  for l:line in l:lines[l:lnum_start : l:lnum_end]
    let l:parts = split(l:line, '\s*|\s*')

    let l:info = {
          \ 'project' : l:parts[0],
          \ 'task' : l:parts[1],
          \ 'hours' : str2float(l:parts[2]),
          \}
    let l:info.remark = get(l:parts, 3, '')
    let l:info.projname = l:info.project
    let l:info.taskno = l:info.task
    let l:info.taskname = l:info.task

    if l:info.hours == 0.0 | continue | endif

    if has_key(s:table, l:info.project)
      let l:p = s:table[l:info.project]
      let l:info.projname = l:p.name
      let l:info.projno = l:p.number
      if empty(l:info.task)
        let l:tasks = items(l:p.tasks)
        if len(l:tasks) == 1
          let l:info.taskname = l:tasks[0][0]
        endif
      endif
      let l:info.taskno = get(l:p.tasks, l:info.taskname)
    elseif l:info.project =~# '(\w*\d\+)'
      let l:info.projname = matchstr(l:info.project, '^.\{-}\ze\s*(')
      let l:info.projno = matchstr(l:info.project, '(\zs.*\ze)')
    endif

    call self.add(l:info, a:dow)
  endfor
endfunction

" }}}1
function! s:timesheet.add(info, dow) abort dict " {{{1
  if !has_key(self.data, a:info.project)
    let self.data[a:info.project] = {
          \ 'projname' : get(a:info, 'projname', ''),
          \ 'projno' : get(a:info, 'projno', ''),
          \ 'tasks' : {},
          \}
  endif

  if !has_key(self.data[a:info.project].tasks, a:info.taskname)
    let self.data[a:info.project].tasks[a:info.taskname] = {
          \ 'taskno' : get(a:info, 'taskno'),
          \}
  endif

  " For easier access
  let l:t = self.data[a:info.project].tasks[a:info.taskname]

  if !has_key(l:t, 'hours')
    let l:t.hours = repeat([0.0], 7)
    let l:t.remarks = repeat([''], 7)
  endif

  let l:t.hours[a:dow-1] = a:info.hours
  let l:t.remarks[a:dow-1] = a:info.remark
endfunction

" }}}1
function! s:timesheet.tableize() abort dict " {{{1
  let l:table = {}
  let l:table.titles = ['Project', 'Task',
        \ 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun', 'Sum']

  let l:table.rows = []
  for l:p in self.data_ordered
    for [l:name, l:t] in items(l:p.tasks)
      call add(l:table.rows,
            \ [l:p.projname, l:name] + l:t.hours + [s:sum(l:t.hours)])
    endfor
  endfor

  let l:table.sums = ['Sum', ''] + repeat([0.0], 8)
  for l:row in l:table.rows
    for l:i in range(2,9)
      let l:table.sums[i] += l:row[i]
    endfor
  endfor

  return l:table
endfunction

" }}}1
function! s:timesheet.maconomize() abort dict " {{{1
  let l:list = []
  let l:errors = []
  for l:data in self.data_ordered
    if empty(l:data.projno)
      call add(l:errors,
            \ 'Lacking project number for "' . l:data.projname . '"')
    endif

    for [l:name, l:task] in items(l:data.tasks)
      if empty(l:task.taskno)
        call add(l:errors,
              \ 'Lacking task number for "' . l:data.projname . '"')
      endif

      call add(l:list, extend(copy(l:task), {
            \ 'projno' : l:data.projno,
            \ 'projname' : l:data.projname,
            \ 'taskname' : l:name,
            \}))
    endfor
  endfor

  if len(l:errors) > 0
    echohl Title
    echo "\nCan't submit to Maconomy; there is missing data."
    echohl ModeMsg
    for l:err in l:errors
      echo '-' l:err
    endfor
    echohl None
    return []
  endif

  return l:list
endfunction

" }}}1

function! s:sum(list) abort " {{{1
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
      \ 'Diverse',
      \ 'Borte',
      \ 'Intern',
      \ 'Leiested',
      \ 'Tekna',
      \ 'Sommerjobb',
      \ 'SommerjobbPR',
      \ 'ELEGANCY',
      \ 'NCCS',
      \ '3dmf',
      \ 'NanoHX',
      \ 'FerroCool',
      \ 'RPT',
      \ 'Trafo',
      \ 'HYVA',
      \]

let s:table.Borte = {
      \ 'number' : '98500100',
      \ 'name' : 'Fravær/Permisjon',
      \ 'tasks' : {
      \   'Omsorg' : 9404,
      \   'Pappaperm' : 9407,
      \   'Lege' : 9409,
      \   'Sjuk' : 9402,
      \   'Sjuke born' : 9406,
      \   'Ferie' : 9413,
      \   'Annet' : 9411,
      \ }
      \}

let s:table.Intern = {
      \ 'number' : '99500121-1',
      \ 'name' : 'Intern',
      \ 'tasks' : {
      \   '' : 9000,
      \ }
      \}

let s:table.Leiested = {
      \ 'number' : 'L5090023',
      \ 'name' : 'Leiested (linux drift)',
      \ 'tasks' : {
      \   'Drift' : 9005,
      \ }
      \}

let s:table.Tekna = {
      \ 'number' : '502000428',
      \ 'name' : 'ATOer',
      \ 'tasks' : {
      \   '' : 10200,
      \ }
      \}

let s:table.Sommerjobb = {
      \ 'number' : '502001561',
      \ 'name' : 'Sommerjobbprosjektet 2017',
      \ 'tasks' : {
      \   'T0' : 1000,
      \   'T1' : 1010,
      \   'T2' : 1020,
      \ }
      \}

let s:table.SommerjobbPR = {
      \ 'number' : '502001561-1',
      \ 'name' : 'SJP 2017 - PR',
      \ 'tasks' : {
      \   'Eureka' : 1002,
      \ }
      \}

let s:table.SommerjobbVL = {
      \ 'number' : '502001561-X',
      \ 'name' : 'SJP 2017 - Veiledning',
      \ 'tasks' : {
      \ }
      \}

let s:table.3dmf = {
      \ 'number' : '502000610',
      \ 'name' : '3dmf',
      \ 'tasks' : {
      \   'Modellering' : 1010,
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
      \   'T5' : 1050,
      \  }
      \}

let s:table.RPT = {
      \ 'number' : '502001038',
      \ 'name' : 'Predict-RPT',
      \ 'tasks' : {
      \   'WP1.1' : 1100,
      \   'WP1.2' : 1110,
      \   'WP2.1' : 1120,
      \   'WP2.2' : 1130,
      \   'WP3.1' : 1140,
      \   'WP3.2' : 1150,
      \   'SP 4'  : 1160,
      \  }
      \}

let s:table.NCCS = {
      \ 'number' : '502001439',
      \ 'name' : 'NCCS',
      \ 'tasks' : {
      \   'Administrasjon' : 1000,
      \  }
      \}

let s:table.ELEGANCY = {
      \ 'number' : '502001175',
      \ 'name' : 'ELEGANCY',
      \ 'tasks' : {
      \   'P2' : 1010,
      \  }
      \}

let s:table.Trafo = {
      \ 'number' : '502001282',
      \ 'name' : 'Trafo',
      \ 'tasks' : {
      \   'WP2' : 1020,
      \  }
      \}

let s:table.HYVA = {
      \ 'number' : '502001546',
      \ 'name' : 'HYVA',
      \ 'tasks' : {
      \   '' : 1020,
      \  }
      \}

" }}}1

" vim: fdm=marker sw=2
