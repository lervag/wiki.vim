" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#ref_target#matcher() abort " {{{1
  return extend(
        \ wiki#link#_template#matcher(),
        \ deepcopy(s:matcher))
endfunction

" }}}1


let s:matcher = {
      \ 'type': 'ref_target',
      \ 'rx': wiki#rx#link_ref_target,
      \ 'rx_url': '\[' . wiki#rx#reftarget . '\]:\s\+\zs' . wiki#rx#url,
      \ 'rx_text': '^\s*\[\zs' . wiki#rx#reftarget . '\ze\]',
      \}

function! s:matcher.toggle(url, id) abort " {{{1
  let l:id = empty(a:id) ? input('Input id: ') : a:id
  return '[' . l:id . '] ' . a:url
endfunction

" }}}1
