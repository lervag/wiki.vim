" A wiki plugin for Vim
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
function! wiki#nav#pop_from_stack() abort " {{{1
  if empty(s:position_stack) | return [] | endif
  return remove(s:position_stack, -1)
endfunction

" }}}1
function! wiki#nav#get_previous() abort "{{{1
  let l:previous = get(s:position_stack, -1, [])
  if !empty(l:previous) | return l:previous | endif

  return {}
endfunction

" }}}1
function! wiki#nav#return() abort "{{{1
  if empty(s:position_stack) | return | endif
  if g:wiki_write_on_nav | update | endif

  let l:previous = remove(s:position_stack, -1)
  silent execute ':edit' fnameescape(l:previous.file)
  call cursor(l:previous.cursor[1:])
endfunction

" }}}1
