" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#list#toggle_todo() "{{{1
  let l:line = getline('.')
  if match(l:line, '^\s*[*-] TODO:') >= 0
    let l:line = substitute(l:line, '^\s*[*-] \zsTODO:\s*\ze', '', '')
    call setline('.', l:line)
  elseif match(l:line, '^\s*[*-] \%(TODO:\)\@!') >= 0
    let l:parts = split(l:line, '^\s*[*-] \zs\s*\ze')
    call setline('.', l:parts[0] . 'TODO: ' . l:parts[1])
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
