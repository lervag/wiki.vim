" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#list#item#parse_tree() abort " {{{1
  let l:items = s:parse_list_to_items()
  return s:parse_items_to_tree(l:items)
endfunction

" }}}1
function! wiki#list#item#get_current(root) abort " {{{1
  if empty(a:root.next) | return {} | endif

  let l:lnum = line('.')
  let l:current = a:root.next
  while l:current.lnum_start < l:lnum
    if !has_key(l:current, 'next') | break | endif
    if l:current.next.lnum_start > l:lnum | break | endif
    let l:current = l:current.next
  endwhile

  return l:current
endfunction

" }}}1

function! s:parse_list_to_items() abort " {{{1
  let l:save_pos = getcurpos()
  let l:cur = l:save_pos[1]

  " Get start of list
  let [l:lnum, l:cnum] = searchpos(
        \ '^\($\|[^ ' . s:re_list_markers . ']\)', 'Wbcn')
  if l:lnum == 0
    let [l:lnum, l:cnum] = [1, 1]
  endif

  call setpos('.', [0, l:lnum, l:cnum, 0])
  let l:start = search(s:re_list_start, 'W')
  call setpos('.', l:save_pos)

  if l:start == 0 || l:start > l:cur
    return []
  endif

  " Get end of list
  let l:end = search('^$', 'Wn')
  if l:end == 0
    let l:end = line('$') + 1
  endif

  " Get lnum pairs for list entries
  let l:lnums = filter(range(l:start, l:end),
        \ 'getline(v:val) =~# s:re_list_start') + [l:end]

  " Create list of items from lnum pairs
  let l:items = []
  let l:lnum_start = l:lnums[0]
  for l:lnum_end in l:lnums[1:]
    call add(l:items, s:item.new(l:lnum_start, l:lnum_end))
    let l:lnum_start = l:lnum_end
  endfor

  return l:items
endfunction

" }}}1
function! s:parse_items_to_tree(items) abort " {{{1
  let l:root = s:item.new_root()
  if empty(a:items) | return l:root | endif

  let l:prev = l:root
  for l:current in a:items
    let l:prev.next = l:current
    let l:current.prev = l:prev

    while l:current.indent <= l:prev.indent
      let l:prev = l:prev.parent
    endwhile

    call add(l:prev.children, l:current)
    let l:current.parent = l:prev
    let l:current.children = []
    let l:prev = l:current
  endfor

  let l:root.nchildren = len(l:root.children)
  for l:item in a:items
    let l:item.nchildren = len(l:item.children)
  endfor

  return l:root
endfunction

" }}}1

let s:re_list_markers = '*-'
let s:re_list_start = '^\s*\zs[' . s:re_list_markers . ']\(\s\|$\)'
let s:re_list_checkbox = '\[[ x]\]'
let s:re_list_checkbox_checked = '\[x\]'

let s:item = {}
function! s:item.new(lnum1, lnum2) abort dict " {{{1
  let l:new = deepcopy(self)
  unlet l:new.new
  unlet l:new.new_root

  let l:new.lnum_start = a:lnum1
  let l:new.lnum_end = a:lnum2-1
  let l:new.text = getline(l:new.lnum_start, l:new.lnum_end)
  let l:new.indent = indent(a:lnum1)

  if match(l:new.text[0], s:re_list_start . s:re_list_checkbox) >= 0
    call s:list_checkbox.init(l:new)
  else
    call s:list_todo.init(l:new)
  endif

  return l:new
endfunction

" }}}1
function! s:item.new_root() abort dict " {{{1
  let l:new = deepcopy(self)
  unlet l:new.new
  unlet l:new.new_root

  let l:new.type = 'root'
  let l:new.next = {}
  let l:new.children = []
  let l:new.indent = -1

  return l:new
endfunction

" }}}1
function! s:item.to_string() abort dict "{{{1
  let l:l1 = get(self, 'lnum_start', -1)
  let l:l2 = get(self, 'lnum_end', -1)

  let l:lines = [
        \ 'List item: "' . get(self, 'text', [''])[0] . '"',
        \ '  lnums: ' . (l:l1 ==# l:l2 ? l:l1 : l:l1 . ' to ' . l:l2),
        \ '  indent: ' . self.indent,
        \ '  type: ' . self.type,
        \ '  checked: ' . get(self, 'checked', 'REMOVE'),
        \ '  state: ' . get(self, 'state', 'REMOVE'),
        \ '  states: ' . string(get(self, 'states', 'REMOVE')),
        \ '  children: ' . len(self.children),
        \]
  return filter(l:lines, 'v:val !~# ''REMOVE''')
endfunction

" }}}1

let s:list_todo = {
      \ 'type' : 'todo',
      \ 'state' : 0,
      \ 'states' : get(g:, 'wiki_list_todos', ['TODO', 'DONE']),
      \}
function! s:list_todo.init(item) abort dict "{{{1
  let l:new = deepcopy(self)
  unlet l:new.init
  call extend(a:item, l:new)

  let a:item.state = index(self.states, matchstr(a:item.text[0],
        \ s:re_list_start . '\zs' . join(self.states, '\|') . '\ze:'))
endfunction

" }}}1
function! s:list_todo.toggle() abort dict "{{{1
  let l:re_old = s:re_list_start . '\zs'
        \ . (self.state < 0 ? '' : self.states[self.state] . ':')
        \ . '\s*\ze'

  let self.state = ((self.state + 2) % (len(self.states) + 1)) - 1

  let l:line = substitute(self.text[0], l:re_old,
        \ self.state >= 0 ? self.states[self.state] . ': ' : '',
        \ '')

  call setline(self.lnum_start, l:line)
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
    let l:line = substitute(self.text[0],
          \ s:re_list_start . '\[\zsx\ze\]', ' ', '')
    let self.checked = 0
  else
    let l:line = substitute(self.text[0],
          \ s:re_list_start . '\[\zs \ze\]', 'x', '')
    let self.checked = 1
  endif
  call setline(self.lnum_start, l:line)
endfunction

" }}}1
