" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#test#finished() abort " {{{1
  for l:error in v:errors
    let l:match = matchlist(l:error, '\(.*\) line \(\d\+\): \(.*\)')
    let l:file = fnamemodify(l:match[1], ':.')
    let l:lnum = l:match[2]
    let l:msg = l:match[3]
    echo printf("%s:%d: %s\n", l:file, l:lnum, l:msg)
  endfor

  if $QUIT
    if len(v:errors) > 0
      cquit
    else
      quitall!
    endif
  endif
endfunction

" }}}1
function! wiki#test#completion(context, ...) abort " {{{1
  let l:base = a:0 > 0 ? a:1 : ''

  silent execute 'normal GO' . a:context . "\<c-x>\<c-o>"
  silent normal! u
  return wiki#complete#omnicomplete(0, l:base)
endfunction

" }}}1
