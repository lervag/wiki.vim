" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#nav#next_link() abort "{{{1
  call search(g:wiki#rx#link, 's')
endfunction

" }}}1
function! wiki#nav#prev_link() abort "{{{1
  if wiki#u#in_syntax('wikiLink.*')
        \ && wiki#u#in_syntax('wikiLink.*', line('.'), col('.')-1)
    call search(g:wiki#rx#link, 'sb')
  endif
  call search(g:wiki#rx#link, 'sb')
endfunction

" }}}1

function! wiki#nav#add_to_stack(link) abort " {{{1
  let s:position_stack += [a:link]
endfunction

let s:position_stack = []

" }}}1
function! wiki#nav#get_previous() abort "{{{1
  let l:previous = get(s:position_stack, -1, [])
  if !empty(l:previous) | return l:previous | endif

  return {}
endfunction

" }}}1
function! wiki#nav#return() abort "{{{1
  if g:wiki_write_on_nav | update | endif
  if empty(s:position_stack) | return | endif

  let l:link = remove(s:position_stack, -1)
  if empty(l:link.origin) | return | endif

  silent execute ':e ' . substitute(l:link.origin, '\s', '\\\0', 'g')

  if has_key(l:link, 'curpos')
    call cursor(l:link.curpos[1:])
  elseif has_key(l:link, 'pos_start')
    call cursor(l:link.pos_start)
  endif
endfunction

" }}}1
