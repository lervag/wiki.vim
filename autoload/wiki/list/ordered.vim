" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#list#ordered#parse() abort " {{{1
  let l:root = s:parse_list()
  if empty(l:root.next) | return [{}, {}] | endif

  let l:lnum = line('.')
  let l:current = l:root.next
  while l:current.lnum_start < l:lnum
    if empty(l:current.next) || l:current.next.lnum_start > l:lnum
      break
    endif
    let l:current = l:current.next
  endwhile

  return [l:root, l:current]
endfunction

" }}}1
function! wiki#list#ordered#prev_start() abort " {{{1
  let l:cursor = getcurpos()

  let [l:lnum, l:cnum] = searchpos('^\n\S', 'Wbcn')
  if l:lnum == 0
    let [l:lnum, l:cnum] = [1, 1]
  endif

  call setpos('.', [0, l:lnum, l:cnum, 0])
  let l:start = search(s:re_item_start, 'Wn')
  call setpos('.', l:cursor)

  if l:start > l:cursor[1]
    let l:start = 0
  endif
  return l:start
endfunction

" }}}1


let s:re_list_number = '\d\+\.'
let s:re_item_start = '^\s*' . s:re_list_number . '\(\s\|$\)'


function! s:parse_list() abort " {{{1
  let l:items = s:parse_list_items()
  if empty(l:items) | return {} | endif

  " Generate linked list tree structure
  let l:root = s:item.new()
  let l:prev = l:root
  let l:prev.lnum_start = l:items[0].lnum_start

  for l:current in l:items
    let l:prev.next = l:current
    let l:current.prev = l:prev

    while l:current.indent <= l:prev.indent
      let l:prev = l:prev.parent
    endwhile

    let l:current.parent = l:prev
    call add(l:prev.children, l:current)
    let l:prev.lnum_last = l:current.lnum_end

    let l:prev = l:current
  endfor

  let l:root.lnum_start = l:root.next.lnum_start
  let l:root.nchildren = len(l:root.children)
  for l:item in l:items
    let l:item.nchildren = len(l:item.children)
  endfor

  return l:root
endfunction

" }}}1
function! s:parse_list_items() abort " {{{1
  let l:start = wiki#list#ordered#prev_start()
  if l:start == 0 | return [] | endif

  " Get end of list
  let l:end = search('^$', 'Wn')
  if l:end == 0
    let l:end = line('$') + 1
  endif

  " Get lnum pairs for list entries
  let l:lnums = filter(range(l:start, l:end),
        \ 'getline(v:val) =~# s:re_item_start') + [l:end]

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

let s:item = {}
function! s:item.new(...) abort dict " {{{1
  " Args: Either zero or two args: lnum_start and lnum_end
  let l:new = deepcopy(self)
  unlet l:new.new

  let l:new.type = 'root'
  let l:new.indent = -1
  let l:new.next = {}
  let l:new.prev = {}
  let l:new.parent = {}
  let l:new.children = []

  if a:0 == 2
    let l:new.lnum_start = a:1
    let l:new.lnum_end = a:2-1
    let l:new.lnum_last = l:new.lnum_end
    let l:new.text = getline(l:new.lnum_start, l:new.lnum_end)
    let l:new.indent = indent(a:1)
    let l:new.header = matchstr(l:new.text[0], s:re_item_start)
    call s:list_todo.init(l:new)
  endif

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
function! s:item.lnum_end_children() abort dict "{{{1
  return self.nchildren > 0
        \ ? self.children[-1].lnum_end_children()
        \ : self.lnum_end
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
        \ s:re_item_start . '\zs' . join(self.states, '\|') . '\ze:'))
endfunction

" }}}1
function! s:list_todo.toggle() abort dict "{{{1
  let l:re_old = s:re_item_start . '\zs'
        \ . (self.state < 0 ? '' : self.states[self.state] . ':')
        \ . '\s*\ze'

  let self.state = ((self.state + 2) % (len(self.states) + 1)) - 1

  let l:line = substitute(self.text[0], l:re_old,
        \ self.state >= 0 ? self.states[self.state] . ': ' : '',
        \ '')

  call setline(self.lnum_start, l:line)
endfunction

" }}}1
