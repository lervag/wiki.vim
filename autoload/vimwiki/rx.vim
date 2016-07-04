" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#rx#generate_bold_italic(chars, ...) " {{{1
  let l:bolded = a:0 > 0 ? a:1
        \ : '[^' . a:chars . '`[:space:]]'
        \ . '\%([^' . a:chars . '`]*[^' . a:chars . '`[:space:]]\)\?'
  return '\%(^\|\s\|[[:punct:]]\)\@<=' . escape(a:chars, '*')
        \ . l:bolded
        \ . escape(join(reverse(split(a:chars, '\zs')), ''), '*')
        \ . '\%([[:punct:]]\|\s\|$\)\@='
endfunction

" }}}1

" vim: fdm=marker sw=2
