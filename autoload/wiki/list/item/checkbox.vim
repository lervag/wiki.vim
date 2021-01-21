" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"


function! wiki#list#item#checkbox#new() abort " {{{1
  return deepcopy(s:item)
endfunction

" }}}1


let s:item = extend(wiki#list#item#unordered#new(), {
      \ 'type' : 'checkbox',
      \ 'checked' : 0,
      \ 're_item': '^\s*[*-] \[[ x]\]\%(\s\|$\)',
      \ 're_item_unchecked': '^\s*[*-] \[\zs \ze\]',
      \ 're_item_checked': '^\s*[*-] \[\zsx\ze\]',
      \})

function! s:item.init() abort dict " {{{1
  let self.checked = match(self.text[0], self.re_item_checked) >= 0
endfunction

" }}}1

function! s:item.toggle() abort dict "{{{1
  call self.toggle_current()
  call self.toggle_children(self.checked)
  call self.toggle_parents(self.checked)
endfunction

" }}}1
function! s:item.toggle_current() abort dict "{{{1
  if self.checked
    let self.checked = 0
    let l:line = substitute(self.text[0], self.re_item_checked, ' ', '')
  else
    let self.checked = 1
    let l:line = substitute(self.text[0], self.re_item_unchecked, 'x', '')
  endif

  call setline(self.lnum_start, l:line)
endfunction

" }}}1
function! s:item.toggle_children(status) abort dict "{{{1
  for l:child in filter(self.children, "v:val.type ==# 'checkbox'")
    if l:child.checked != a:status
      call l:child.toggle_current()
    endif
    call l:child.toggle_children(a:status)
  endfor
endfunction

" }}}1
function! s:item.toggle_parents(status) abort dict "{{{1
  let l:parent = self.parent
  if l:parent.type !=# 'checkbox' | return | endif

  let l:children_checked = 1
  for l:item in l:parent.children
    if !get(l:item, 'checked', 1)
      let l:children_checked = 0
      break
    endif
  endfor

  if (a:status && !l:parent.checked && l:children_checked)
        \ || (!a:status && l:parent.checked)
    call l:parent.toggle_current()
  endif

  call l:parent.toggle_parents(a:status)
endfunction

" }}}1
