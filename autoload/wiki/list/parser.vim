" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#list#parser#get_at(lnum) abort "{{{1
  let l:save_pos = getcurpos()

  call setpos('.', [0, a:lnum, 1, 0])
  let [l:root, l:current] = s:get_list()
  call setpos('.', l:save_pos)

  return [l:root, l:current]
endfunction

" }}}1
function! wiki#list#parser#get_current() abort "{{{1
  return s:get_list()
endfunction

" }}}1
function! wiki#list#parser#get_previous() abort "{{{1
  return s:get_list({'previous': v:true})
endfunction

" }}}1


function! s:get_list(...) abort " {{{1
  let l:opts = extend({
        \ 'previous': v:false,
        \}, a:0 > 0 ? a:1 : {})

  call s:init_item_types()

  let l:items = s:get_list_items(l:opts)
  let l:root = s:get_tree_from_items(l:items)

  return [l:root, s:get_current_item(l:root)]
endfunction

" }}}1

function! s:get_list_items(opts) abort " {{{1
  " Find a position above the list
  let [l:lnum, l:cnum] = searchpos('^\n\S', 'Wbn')
  if l:lnum == 0
    let [l:lnum, l:cnum] = [1, 1]
  endif

  let l:save_pos = getcurpos()
  call setpos('.', [0, l:lnum, l:cnum, 0])
  let l:list_start = search(s:items_re, 'Wn')
  if l:list_start == 0
        \ || l:list_start > l:save_pos[1]
    call setpos('.', l:save_pos)
    return []
  endif

  " Search for list end
  let l:list_end = search('^$', 'Wn')
  let l:list_end = l:list_end > 0 ? l:list_end : line('$') + 1
  call setpos('.', l:save_pos)
  if l:list_end < l:save_pos[1] && !a:opts.previous
    return []
  endif

  " Get line numbers for the list entries
  let l:item_lnums = filter(
        \ range(l:list_start, l:list_end),
        \ 'getline(v:val) =~# s:items_re') + [l:list_end]

  " Create list of items from lnum pairs
  let l:items = []
  let l:item_start = l:item_lnums[0]
  for l:item_end in l:item_lnums[1:]
    for l:item_type in s:items
      if getline(l:item_start) =~# l:item_type.re_item
        call add(l:items, l:item_type.new(l:item_start, l:item_end))
        break
      endif
    endfor

    let l:item_start = l:item_end
  endfor

  return l:items
endfunction

" }}}1
function! s:get_tree_from_items(items) abort " 
  if empty(a:items) | return {} | endif

  " Create root node
  let l:root = {
        \ 'type': 'root',
        \ 'indent': -1,
        \ 'next': {},
        \ 'prev': {},
        \ 'next_sibling': {},
        \ 'prev_sibling': {},
        \ 'parent': {},
        \ 'children': [],
        \}
  let l:root.lnum_start = a:items[0].lnum_start
  let l:root.lnum_end = a:items[-1].lnum_end

  " Fill in tree from items
  let l:counter = 0
  let l:prev = l:root
  for l:current in a:items
    let l:prev.next = l:current
    let l:current.prev = l:prev
    let l:current.next_sibling = {}
    let l:current.prev_sibling = {}

    " Get previous sibling
    let l:prev_sibling = copy(l:prev)
    while l:prev_sibling.indent > l:current.indent
      let l:prev_sibling = l:prev_sibling.parent
    endwhile
    if l:prev_sibling.indent == l:current.indent
      let l:prev_sibling.next_sibling = l:current
      let l:current.prev_sibling = l:prev_sibling
    endif

    " Get parent
    let l:parent = l:prev
    while l:parent.indent >= l:current.indent
      let l:parent = l:parent.parent
    endwhile
    let l:current.parent = l:parent

    " Update parent
    call add(l:parent.children, l:current)
    let l:parent.lnum_last = l:current.lnum_end

    " Update total counter
    let l:counter += 1
    let l:current.counter = l:counter

    " Update nested counter
    if l:prev == l:parent
      let l:counter_nested = 1
    else
      if l:prev.indent > l:current.indent
        let l:counter_nested = l:current.prev_sibling.counter_nested
      endif
      let l:counter_nested += 1
    endif
    let l:current.counter_nested = l:counter_nested

    let l:prev = l:current
  endfor

  " Perform some post calculations
  let l:root.lnum_start = l:root.next.lnum_start
  let l:root.nchildren = len(l:root.children)
  for l:item in a:items
    let l:item.nchildren = len(l:item.children)
  endfor

  return l:root
endfunction

" }}}1
function! s:get_current_item(root) abort " {{{1
  if empty(a:root) | return {} | endif

  let l:current = a:root.next
  let l:lnum = line('.')
  while l:current.lnum_start < l:lnum
    if empty(l:current.next) || l:current.next.lnum_start > l:lnum
      break
    endif
    let l:current = l:current.next
  endwhile

  return l:current
endfunction

" }}}1

function! s:init_item_types() abort " {{{1
  if exists('s:items') | return | endif

  let l:regexes = []
  let l:items = []
  for l:t in map(glob(s:glob_path, 0, 1), "fnamemodify(v:val, ':t:r')")
    if l:t ==# 'general' | continue | endif

    let l:item_type = wiki#list#item#{l:t}#new()
    call add(l:items, l:item_type)

    if index(l:regexes, l:item_type.re_item) < 0
      call add(l:regexes, l:item_type.re_item)
    endif
  endfor

  let s:items = l:items
  let s:items_re = join(l:regexes, '\|')
endfunction

let s:glob_path = fnamemodify(expand('<sfile>'), ':h') . '/item/*.vim'

" }}}1
