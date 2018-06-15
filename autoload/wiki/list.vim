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

  let l:root = wiki#list#item#parse_tree()
  let l:current = wiki#list#item#get_current(l:root)

  if a:0 > 0
    call setpos('.', l:save_pos)
  endif

  return [l:root, l:current]
endfunction

" }}}1
function! wiki#list#toggle(...) abort "{{{1
  let [l:root, l:current] = a:0 > 0
        \ ? wiki#list#get(a:1)
        \ : wiki#list#get()
  if empty(l:current) | return | endif

  call l:current.toggle()
endfunction

" }}}1
function! wiki#list#uniq(local, ...) abort "{{{1
  let [l:root, l:current] = a:0 > 0
        \ ? wiki#list#get(a:1)
        \ : wiki#list#get()
  if empty(l:current) | return | endif

  let l:parent = a:local ? l:current.parent : l:root

  let l:list_parsed = s:uniq_parse(l:parent.children)
  let l:list_new = s:uniq_to_text(l:list_parsed)

  let l:last = l:parent.children[-1]
  while !empty(l:last.children)
    let l:last = l:last.children[-1]
  endwhile
  let l:start = l:parent.children[0].lnum_start
  let l:end = l:last.lnum_end

  let l:save_pos = getcurpos()
  silent execute printf('%d,%ddelete _', l:start, l:end)
  call append(l:start-1, l:list_new)
  call setpos('.', l:save_pos)
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

function! s:uniq_parse(items) abort "{{{1
  let l:uniq = []

  for l:e in a:items
    let l:found = 0
    for l:u in l:uniq
      if join(l:u.text) ==# join(l:e.text)
        call extend(l:u.children, l:e.children)
        let l:found = 1
        break
      endif
    endfor

    if !l:found
      call add(l:uniq, {
            \ 'text' : l:e.text,
            \ 'children' : l:e.children,
            \})
    endif
  endfor

  for l:u in l:uniq
    let l:u.children = s:uniq_parse(l:u.children)
  endfor

  return l:uniq
endfunction

" }}}1
function! s:uniq_to_text(tree) abort "{{{1
  let l:text = []

  for l:leaf in a:tree
    call extend(l:text, l:leaf.text)

    if !empty(l:leaf.children)
      call extend(l:text, s:uniq_to_text(l:leaf.children))
    endif
  endfor

  return l:text
endfunction

" }}}1
