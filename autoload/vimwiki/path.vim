" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#path#chomp_slash(str) "{{{1
  return substitute(a:str, '[/\\]\+$', '', '')
endfunction

"}}}1
function! vimwiki#path#is_equal(p1, p2) " {{{1
  return a:p1 ==# a:p2
endfunction

"}}}1
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
  " /-slashes
  if a:path !~# '^scp:'
    let path = substitute(a:path, '\', '/', 'g')
    " treat multiple consecutive slashes as one path separator
    let path = substitute(path, '/\+', '/', 'g')
    " ensure that we are not fooled by a symbolic link
    return resolve(path)
  else
    return a:path
  endif
endfunction

"}}}1
function! vimwiki#path#is_link_to_dir(link) "{{{1
  " Check if link is to a directory.
  " It should be ended with \ or /.
  return a:link =~# '\m[/\\]$'
endfunction

"}}}1
function! vimwiki#path#abs_path_of_link(link) "{{{1
  return vimwiki#path#normalize(expand("%:p:h").'/'.a:link)
endfunction

"}}}1
function! vimwiki#path#path_common_pfx(path1, path2) "{{{1
  let p1 = split(a:path1, '[/\\]', 1)
  let p2 = split(a:path2, '[/\\]', 1)

  let idx = 0
  let minlen = min([len(p1), len(p2)])
  while (idx < minlen) && vimwiki#path#is_equal(p1[idx], p2[idx])
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
  let result = resolve(expand(a:path, ':p'))
  let result = vimwiki#path#chomp_slash(result)
  return result
endfunction

"}}}1
function! vimwiki#path#relpath(dir, file) "{{{1
  let result = []
  let dir = split(a:dir, '/')
  let file = split(a:file, '/')
  while (len(dir) > 0 && len(file) > 0) && vimwiki#path#is_equal(dir[0], file[0])
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
function! vimwiki#path#mkdir(path, ...) "{{{1
  let path = expand(a:path)

  if path =~# '^scp:'
    " we can not do much, so let's pretend everything is ok
    return 1
  endif

  if isdirectory(path)
    return 1
  else
    if !exists("*mkdir")
      return 0
    endif

    let path = vimwiki#path#chomp_slash(path)

    if a:0 && a:1 && input("Vimwiki: Make new directory: "
          \ .path."\n [y]es/[N]o? ") !~? '^y'
      return 0
    endif

    call mkdir(path, "p")
    return 1
  endif
endfunction " }}}
function! vimwiki#path#is_absolute(path) "{{{1
  return a:path =~# '\m^/\|\~/'
endfunction

"}}}1
function! vimwiki#path#join_path(directory, file) " {{{1
  let directory = substitute(a:directory, '\m/\+$', '', '')
  let file = substitute(a:file, '\m^/\+', '', '')
  return directory . '/' . file
endfunction

" }}}1

" vim: fdm=marker sw=2
