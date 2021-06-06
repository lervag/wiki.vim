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

  if a:is_inner && has_key(l:link, 'url_pos_start')
    let l:p1 = l:link.url_pos_start
    let l:p2 = l:link.url_pos_end
  else
    let l:p1 = l:link.pos_start
    let l:p2 = l:link.pos_end
  endif

  call cursor(l:p1)
  normal! v
  call cursor(l:p2)
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

  let l:p1 = l:link.text_pos_start
  let l:p2 = l:link.text_pos_end
  if !a:is_inner && l:link.type ==# 'wiki'
    let l:p1[1] -= 1
  endif

  call cursor(l:p1)
  normal! v
  call cursor(l:p2)
endfunction

" }}}1
