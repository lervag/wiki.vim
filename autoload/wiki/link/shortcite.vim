" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#shortcite#matcher() abort " {{{1
  return extend(
        \ wiki#link#_template#matcher(),
        \ deepcopy(s:matcher))
endfunction

" }}}1


let s:matcher = {
      \ 'type': 'url',
      \ 'rx': wiki#rx#link_shortcite,
      \}

function! s:matcher.parse(link) abort dict " {{{1
  let a:link.url = 'zot:' . strpart(a:link.full, 1)

  return wiki#url#extend(a:link)
endfunction

" }}}1
