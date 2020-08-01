" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#text_obj#link(is_inner, vmode) abort " {{{1
  let l:link = wiki#link#get()
  if empty(l:link)
    if a:vmode
      normal! gv
    endif
    return
  endif

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
function! wiki#text_obj#link_text(is_inner, vmode) abort " {{{1
  let l:link = wiki#link#get()
  if empty(l:link) || empty(l:link.text)
    if a:vmode
      normal! gv
    endif
    return
  endif

  let l:c1 = l:link.text_c1
  if !a:is_inner && l:link.type ==# 'wiki'
    let l:c1 -= 1
  endif

  call cursor(l:link.lnum, l:c1)
  normal! v
  call cursor(l:link.lnum, l:link.text_c2)
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

  while v:true
    let l:start = [l:current.lnum_start, 1]
    let l:end = [l:current.lnum_end_children(), 1]
    let l:end[1] = strlen(getline(l:end[0]))
    let l:linewise = 1

    if a:is_inner
      let l:start[1] = 3 + indent(l:start[0])
      let l:linewise = 0
    endif

    if !a:vmode
          \ || l:current.type ==# 'root'
          \ || l:start != getpos('''<')[1:2]
          \ || l:end[0] != getpos('''>')[1]
          \ | break | endif

    let l:current = l:current.parent
  endwhile

  call cursor(l:start)
  execute 'normal!' (l:linewise ? 'V' : 'v')
  call cursor(l:end)
endfunction

" }}}1
