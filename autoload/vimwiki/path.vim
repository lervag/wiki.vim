" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#path#normalize(path) "{{{1
  let path = a:path
  while 1
    let result = substitute(path, '/[^/]\+/\.\.', '', '')
    if result ==# path
      break
    endif
    let path = result
  endwhile
  return result
endfunction

"}}}1
function! vimwiki#path#path_norm(path) "{{{1
  return resolve(substitute(a:path, '/\+', '/', 'g'))
endfunction

"}}}1
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
function! vimwiki#path#wikify_path(path) "{{{1
  return substitute(resolve(expand(a:path, ':p')), '[/\\]\+$', '', '')
endfunction

"}}}1
function! vimwiki#path#relpath(dir, file) "{{{1
  let result = []
  let dir = split(a:dir, '/')
  let file = split(a:file, '/')
  while (len(dir) > 0 && len(file) > 0) && resolve(dir[0]) ==# resolve(file[0])
    call remove(dir, 0)
    call remove(file, 0)
  endwhile
  if empty(dir) && empty(file)
    return './'
  endif
  for segment in dir
    let result += ['..']
  endfor
  for segment in file
    let result += [segment]
  endfor
  let result_path = join(result, '/')
  if a:file =~ '\m/$'
    let result_path .= '/'
  endif
  return result_path
endfunction

"}}}1

" vim: fdm=marker sw=2
