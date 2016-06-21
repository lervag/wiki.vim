" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#path#path_common_pfx(path1, path2) "{{{1
  let p1 = split(a:path1, '[/\\]', 1)
  let p2 = split(a:path2, '[/\\]', 1)

  let idx = 0
  let minlen = min([len(p1), len(p2)])
  while (idx < minlen) && resolve(p1[idx]) ==# resolve(p2[idx])
    let idx = idx + 1
  endwhile
  if idx == 0
    return ''
  else
    return join(p1[: idx-1], '/')
  endif
endfunction

"}}}1

" vim: fdm=marker sw=2
