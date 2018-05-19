" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#list#get(...) abort "{{{1
  if a:0 > 0
    let l:save_pos = getcurpos()
    call setpos('.', [0, a:1, 1, 0])
  endif
  let l:root = s:get_list_connect(s:get_list_items())

  if empty(l:root.next) | return [l:root, {}] | endif

  let l:lnum = line('.')
  let l:current = l:root.next
  while l:current.lnum < l:lnum
    if !has_key(l:current, 'next') | break | endif
    if l:current.next.lnum > l:lnum | break | endif
    let l:current = l:current.next
  endwhile

  if a:0 > 0
    call setpos('.', l:save_pos)
  endif

  return [l:root, l:current]
endfunction

" }}}1
function! wiki#list#toggle(...) abort "{{{1
  if a:0 > 0
    let l:save_pos = getcurpos()
    call setpos('.', [0, a:1, 1, 0])
  endif

  let [l:root, l:current] = wiki#list#get()
  if empty(l:current) | return | endif

  call l:current.toggle()

  if a:0 > 0
    call setpos('.', l:save_pos)
  endif
endfunction

" }}}1
function! wiki#list#print(item) abort "{{{1
  let l:lines = [
        \ 'List item: "' . get(a:item, 'text', '') . '"',
        \ '  lnum: ' . get(a:item, 'lnum'),
        \ '  indent: ' . a:item.indent,
        \ '  type: ' . a:item.type,
        \ '  checked: ' . get(a:item, 'checked', 'REMOVE'),
        \ '  state: ' . get(a:item, 'state', 'REMOVE'),
        \ '  states: ' . string(get(a:item, 'states', 'REMOVE')),
        \ '  children: ' . len(a:item.children),
        \]
  return filter(l:lines, 'v:val !~# ''REMOVE''')
endfunction

" }}}1

function! wiki#list#new_line_bullet() abort "{{{1
  let l:re = '\v^\s*[*-] %(TODO:)?\s*'
  let l:line = getline('.')

  " Toggle TODO if at start of list item
  if match(l:line, l:re . '$') >= 0
    let l:re = '\v^\s*[*-] \zs%(TODO:)?\s*'
    return repeat("\<bs>", strlen(matchstr(l:line, l:re)))
          \ . (match(l:line, 'TODO') < 0 ? 'TODO: ' : '')
  endif

  " Find last used bullet type (including the TODO)
  let l:lnum = search(l:re, 'bn')
  let l:bullet = matchstr(getline(l:lnum), l:re)

  " Return new line (unless current line is empty) and the correct bullet
  return (match(l:line, '^\s*$') >= 0 ? '' : "\<cr>") . "0\<c-d>" . l:bullet
endfunction

" }}}1

let s:re_list_markers = '*-'
let s:re_list_start = '^\s*\zs[' . s:re_list_markers . ']\(\s\|$\)'
let s:re_list_checkbox = '\[[ x]\]'
let s:re_list_checkbox_checked = '\[x\]'

function! s:get_list_connect(items) abort " {{{1
  let l:root = {}
  let l:root.type = 'root'
  let l:root.next = {}
  let l:root.children = []
  if empty(a:items) | return l:root | endif

  let l:root.indent = a:items[0].indent - 2
  let l:prev = l:root

  for l:item in a:items
    let l:prev.next = l:item
    let l:item.prev = l:prev

    while l:item.indent <= l:prev.indent
      let l:prev = l:prev.parent
    endwhile

    call add(l:prev.children, l:item)
    let l:item.parent = l:prev
    let l:item.children = []

    let l:prev = l:item
  endfor

  return l:root
endfunction

" }}}1
function! s:get_list_items() abort " {{{1
  let l:items = []
  for l:lnum in s:get_list_range()
    let l:line = getline(l:lnum)
    if l:line !~# s:re_list_start | continue | endif

    let l:item = {}
    let l:item.lnum = l:lnum
    let l:item.text = l:line
    let l:item.indent = indent(l:lnum)

    if match(l:line, s:re_list_start . s:re_list_checkbox) >= 0
      call s:list_checkbox.init(l:item)
    else
      call s:list_todo.init(l:item)
    endif

    call add(l:items, l:item)
  endfor

  return l:items
endfunction

" }}}1
function! s:get_list_range() abort " {{{1
  let l:save_pos = getcurpos()
  let l:cur = l:save_pos[1]

  "
  " Get start of list
  "
  let [l:lnum, l:cnum] = searchpos(
        \ '^\($\|[^ ' . s:re_list_markers . ']\)', 'Wbcn')
  if l:lnum == 0
    let [l:lnum, l:cnum] = [1, 1]
  endif

  call setpos('.', [0, l:lnum, l:cnum, 0])
  let l:start = search(s:re_list_start, 'W')

  "
  " Get end of list
  "
  let [l:end, l:cnum] = searchpos(
        \ '^\($\|[^ ' . s:re_list_markers . ']\)\|\%$', 'Wn')
  if l:end > 0
    call setpos('.', [0, l:end, l:cnum, 0])
    let l:end = search(s:re_list_start, 'Wbcn')
  endif
  if l:end < l:cur
    let l:end = l:start - 1
  endif

  "
  " Return range of list lines
  "
  call setpos('.', l:save_pos)
  return range(l:start, l:end)
endfunction

" }}}1

let s:list_todo = {
      \ 'type' : 'todo',
      \ 'state' : 0,
      \ 'states' : get(g:, 'wiki_list_todo', ['TODO', 'DONE']),
      \}
function! s:list_todo.init(item) abort dict "{{{1
  let l:new = deepcopy(self)
  unlet l:new.init
  call extend(a:item, l:new)

  let a:item.state = index(self.states, matchstr(a:item.text,
        \ s:re_list_start . '\zs' . join(self.states, '\|') . '\ze:'))
endfunction

" }}}1
function! s:list_todo.toggle() abort dict "{{{1
  let l:line = getline(self.lnum)

  let l:re_old = s:re_list_start . '\zs'
        \ . (self.state < 0 ? '' : self.states[self.state] . ':')
        \ . '\s*\ze'

  let self.state = ((self.state + 2) % (len(self.states) + 1)) - 1

  let l:line = substitute(l:line, l:re_old,
        \ self.state >= 0 ? self.states[self.state] . ': ' : '',
        \ '')

  call setline(self.lnum, l:line)
endfunction

" }}}1

let s:list_checkbox = {
      \ 'type' : 'checkbox',
      \ 'checked' : 0,
      \}
function! s:list_checkbox.init(item) abort dict "{{{1
  let l:new = deepcopy(self)
  unlet l:new.init
  call extend(a:item, l:new)

  let a:item.checked = match(a:item.text,
        \ s:re_list_start . s:re_list_checkbox_checked) >= 0
endfunction

" }}}1
function! s:list_checkbox.toggle() abort dict "{{{1
  call self.toggle_current()
  call self.toggle_children(self.checked)
  call self.toggle_parents(self.checked)
endfunction

" }}}1
function! s:list_checkbox.toggle_children(status) abort dict "{{{1
  for l:child in filter(self.children, 'v:val.type ==# ''checkbox''')
    if l:child.checked != a:status
      call l:child.toggle_current()
    endif
    call l:child.toggle_children(a:status)
  endfor
endfunction

" }}}1
function! s:list_checkbox.toggle_parents(status) abort dict "{{{1
  let l:parent = self.parent
  if l:parent.type !=# 'checkbox' | return | endif

  let l:children_checked = 1
  for l:item in l:parent.children
    if !get(l:item, 'checked', 1)
      let l:children_checked = 0
      break
    endif
  endfor

  if (a:status && !l:parent.checked && l:children_checked)
        \ || (!a:status && l:parent.checked)
    call l:parent.toggle_current()
  endif

  call l:parent.toggle_parents(a:status)
endfunction

" }}}1
function! s:list_checkbox.toggle_current() abort dict "{{{1
  if self.checked
    let l:line = substitute(getline(self.lnum),
          \ s:re_list_start . '\[\zsx\ze\]', ' ', '')
    let self.checked = 0
  else
    let l:line = substitute(getline(self.lnum),
          \ s:re_list_start . '\[\zs \ze\]', 'x', '')
    let self.checked = 1
  endif
  call setline(self.lnum, l:line)
endfunction

" }}}1
