" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#nav#next_link() abort "{{{1
  call search(wiki#rx#link(), 's')
endfunction

" }}}1
function! wiki#nav#prev_link() abort "{{{1
  if wiki#u#in_syntax('wikiLink.*')
        \ && wiki#u#in_syntax('wikiLink.*', line('.'), col('.')-1)
    call search(wiki#rx#link(), 'sb')
  endif
  call search(wiki#rx#link(), 'sb')
endfunction

" }}}1

function! wiki#nav#return() abort "{{{1
  if g:wiki_write_on_nav | update | endif

  if !empty(s:position_stack)
    let [l:file, l:pos] = remove(s:position_stack, -1)
    silent execute ':e ' . substitute(l:file, '\s', '\\\0', 'g')
    call setpos('.', l:pos)
  else
    silent! execute "normal! \<c-o>"
  endif
endfunction

" }}}1
function! wiki#nav#add_to_stack(link) abort " {{{1
  let s:position_stack += [a:link]
endfunction

let s:position_stack = []

" }}}1
