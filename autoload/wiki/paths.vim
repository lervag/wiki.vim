" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#paths#shorten_relative(path) abort " {{{1
  " Input: An absolute path
  " Output: Relative path with respect to the wiki root, path relative to
  "         wiki root (unless absolute path is shorter)

  let l:relative = wiki#paths#relative(a:path, wiki#get_root())
  return strlen(l:relative) < strlen(a:path)
        \ ? l:relative : a:path
endfunction

" }}}1
function! wiki#paths#relative(path, current) abort " {{{1
  " Note: This algorithm is based on the one presented by @Offirmo at SO,
  "       http://stackoverflow.com/a/12498485/51634
  let l:target = substitute(a:path, '\\', '/', 'g')
  let l:common = substitute(a:current, '\\', '/', 'g')

  let l:result = ''
  while stridx(l:target, l:common) != 0
    let l:common = fnamemodify(l:common, ':h')
    let l:result = empty(l:result) ? '..' : '../' . l:result
  endwhile

  if l:common ==# '/'
    let l:result .= '/'
  endif

  let l:forward = strpart(l:target, strlen(l:common))
  if !empty(l:forward)
    let l:result = empty(l:result)
          \ ? l:forward[1:]
          \ : l:result . l:forward
  endif

  return l:result
endfunction

" }}}1
