" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"


function! wiki#list#item#general#new() abort " {{{1
  return deepcopy(s:item)
endfunction

" }}}1


let s:item = {
      \ 'type' : 'none',
      \ 'indent': -1,
      \ 'next': {},
      \ 'prev': {},
      \ 'parent': {},
      \ 'children': [],
      \ 'state' : -1,
      \ 'states' : get(g:, 'wiki_list_todos', ['TODO', 'DONE']),
      \}

function! s:item.new(start, end) abort dict " {{{1
  let l:new = deepcopy(self)
  unlet l:new.new

  let l:new.lnum_start = a:start
  let l:new.lnum_end = a:end - 1
  let l:new.lnum_last = l:new.lnum_end
  let l:new.text = getline(l:new.lnum_start, l:new.lnum_end)
  let l:new.indent = indent(a:start)

  " This is a template and must be combined with a real item type!
  if !has_key(self, 're_item')
    call wiki#log#error('THIS IS A GENERIC FUNCTION!')
    return {}
  endif

  let l:new.header = matchstr(l:new.text[0], self.re_item)
  let l:new.state = index(self.states, matchstr(l:new.text[0],
        \ self.re_item . '\zs' . join(self.states, '\|') . '\ze:'))

  if has_key(l:new, 'init')
    call l:new.init()
    unlet l:new.init
  endif

  return l:new
endfunction

" }}}1

function! s:item.lnum_end_children() abort dict "{{{1
  return self.nchildren > 0
        \ ? self.children[-1].lnum_end_children()
        \ : self.lnum_end
endfunction

" }}}1
function! s:item.to_string() abort dict "{{{1
  let l:l1 = self.lnum_start
  let l:l2 = self.lnum_end

  let l:counter_nested = []
  let l:p = self
  while !empty(l:p.parent)
    call insert(l:counter_nested, l:p.counter_nested, 0)
    let l:p = l:p.parent
  endwhile

  let l:lines = [
        \ 'text: ' . self.text[0],
        \ 'type: ' . self.type,
        \ 'number: ' . self.counter,
        \ 'number nested: ' . join(counter_nested, '.'),
        \ 'lnums: ' . (l:l1 ==# l:l2 ? l:l1 : l:l1 . ' to ' . l:l2),
        \ 'indent: ' . self.indent,
        \ 'checked: ' . get(self, 'checked', 'REMOVE'),
        \ 'state: ' . get(self, 'state', 'REMOVE'),
        \ 'states: ' . string(get(self, 'states', 'REMOVE')),
        \ 'children: ' . len(self.children),
        \]

  return filter(l:lines, 'v:val !~# ''REMOVE''')
endfunction

" }}}1
function! s:item.toggle() abort dict "{{{1
  let l:re_old = self.re_item . '\zs'
        \ . (self.state < 0 ? '' : self.states[self.state] . ':')
        \ . '\s*\ze'

  let self.state = ((self.state + 2) % (len(self.states) + 1)) - 1

  let l:line = substitute(self.text[0], l:re_old,
        \ self.state >= 0 ? self.states[self.state] . ': ' : '',
        \ '')

  call setline(self.lnum_start, l:line)
endfunction

" }}}1
