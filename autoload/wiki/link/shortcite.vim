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

function! s:matcher.parse_url() abort dict " {{{1
  let self.url = 'zot:' . strpart(self.content, 1)
endfunction

" }}}1
