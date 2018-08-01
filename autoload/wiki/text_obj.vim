" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#text_obj#link(is_inner) abort " {{{1
  let l:link = wiki#link#get_at_cursor()
  if empty(l:link) | return | endif

  if a:is_inner && has_key(l:link, 'url_c1')
    let l:c1 = l:link.url_c1
    let l:c2 = l:link.url_c2
  else
    let l:c1 = l:link.c1
    let l:c2 = l:link.c2
  endif

  call cursor(l:link.lnum, l:c1)
  normal! v
  call cursor(l:link.lnum, l:c2)
endfunction

" }}}1
function! wiki#text_obj#link_text(is_inner, ...) abort " {{{1
  let l:link = wiki#link#get_at_cursor()
  if empty(l:link) | return | endif
  if empty(l:link.text) | return | endif

  let l:c1 = l:link.text_c1
  if !a:is_inner && l:link.type ==# 'wiki'
    let l:c1 -= 1
  endif

  call cursor(l:link.lnum, l:c1)
  normal! v
  call cursor(l:link.lnum, l:link.text_c2)
endfunction

" }}}1
function! wiki#text_obj#code(is_inner) abort " {{{1
  if !wiki#u#is_code(line('.')) | return | endif

  let l:lnum1 = line('.')
  while 1
    if !wiki#u#is_code(l:lnum1-1) | break | endif
    let l:lnum1 -= 1
  endwhile

  let l:lnum2 = line('.')
  while 1
    if !wiki#u#is_code(l:lnum2+1) | break | endif
    let l:lnum2 += 1
  endwhile

  if a:is_inner
    let l:lnum1 += 1
    let l:lnum2 -= 1
  endif

  call cursor(l:lnum1, 1)
  normal! v
  call cursor(l:lnum2, strlen(getline(l:lnum2)))
endfunction

" }}}1
function! wiki#text_obj#list_element(is_inner, vmode) abort " {{{1
  let [l:root, l:current] = wiki#list#get()
  if empty(l:current)
    if a:vmode
      normal! gv
    endif
    return
  endif

  if a:is_inner
    let l:lnum1 = l:current.lnum_start
    let l:lnum2 = l:current.nchildren > 0
          \ ? l:current.children[-1].lnum_end
          \ : l:current.lnum_end
  else
    let l:lnum1 = l:current.parent.type == 'root'
          \ ? l:current.parent.children[0].lnum_start
          \ : l:current.parent.lnum_start
    let l:lnum2 = l:current.parent.children[-1].lnum_end
  endif

  call cursor(l:lnum1, 1)
  normal! V
  call cursor(l:lnum2, strlen(getline(l:lnum2)))
endfunction

" }}}1
