" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#list#toggle() "{{{1
  let l:line = getline('.')
  if match(l:line, '^\s*[*-] TODO:') >= 0
    let l:line = substitute(l:line, '^\s*[*-] \zsTODO:\s*\ze', '', '')
    call setline('.', l:line)
  elseif match(l:line, '^\s*[*-] \[x\]') >= 0
    let l:line = substitute(l:line, '^\s*[*-] \[\zsx\ze\]', ' ', '')
    call setline('.', l:line)
  elseif match(l:line, '^\s*[*-] \[ \]') >= 0
    let l:line = substitute(l:line, '^\s*[*-] \[\zs \ze\]', 'x', '')
    call setline('.', l:line)
  elseif match(l:line, '^\s*[*-] \%(TODO:\)\@!') >= 0
    let l:parts = split(l:line, '^\s*[*-] \zs\s*\ze')
    call setline('.', l:parts[0] . 'TODO: ' . l:parts[1])
  endif
endfunction

" }}}1

function! wiki#list#new_line_bullet() "{{{1
  let l:re = '\v^\s*[*-] %(TODO:)?\s*'
  let l:line = getline('.')

  " Toggle TODO if at start of list item
  if match(l:line, l:re . '$') >= 0
    let l:re = '\v^\s*[*-] \zs%(TODO:)?\s*'
    return repeat("\<bs>", strlen(matchstr(l:line, l:re)))
          \ . (match(l:line, 'TODO') < 0 ? 'TODO: ' : '')
  endif

  " Find last used bullet type (including the TODO)
  let l:lnum = search(l:re, 'bn')
  let l:bullet = matchstr(getline(l:lnum), l:re)

  " Return new line (unless current line is empty) and the correct bullet
  return (match(l:line, '^\s*$') >= 0 ? '' : "\<cr>") . "0\<c-d>" . l:bullet
endfunction

" }}}1

" vim: fdm=marker sw=2
