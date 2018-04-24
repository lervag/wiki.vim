" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#complete#omnicomplete(findstart, base) " {{{1
  if a:findstart
    let s:ctx = {}
    let l:line = getline('.')[:col('.')-2]
    let l:cnum = match(l:line, s:re_complete_trigger)
    if l:cnum < 0 | return -1 | endif

    let l:base = l:line[l:cnum:]
    if l:base =~# '#'
      let l:split = split(l:base, '#', 1)
      let s:ctx.url = l:split[0]
      let s:ctx.pre_anch = l:split[1:-2]
      let l:cnum += strlen(join(l:split[:-2], '#')) + 1
    endif

    return l:cnum
  else
    if !empty(s:ctx)
      let l:url = wiki#url#parse(empty(s:ctx.url) ? expand('%:t:r') : s:ctx.url)
      let l:pre_base = join(s:ctx.pre_anch, '#') . '#'
      let l:cnum = strlen(l:pre_base)
      let l:anchors = filter(wiki#page#get_anchors(l:url),
            \ 'v:val =~# ''^'' . wiki#u#escape(l:pre_base) . ''[^#]*$''')
      return map(l:anchors, 'strpart(v:val, l:cnum)')
    else
      if a:base[0] ==# '/'
        let l:cwd = resolve(wiki#get_root())
        let l:cands = map(globpath(l:cwd, '**/*.wiki', 0, 1),
              \ '''/'' . s:relpath(l:cwd, fnamemodify(v:val, '':r''))')
      else
        let l:cands = map(globpath(expand('%:p:h'), '**/*.wiki', 0, 1),
              \ 'resolve(fnamemodify(v:val, '':.:r''))')
      endif

      return filter(l:cands, 'v:val =~# ''^'' . wiki#u#escape(a:base)')
    endif
  endif
endfunction

" }}}1

let s:re_complete_trigger = join([
      \ '\[\[\zs[^\\[\]]*',
      \ '\[[^]]*\](\zs[^)]*',
      \ 'journal:\zs\S*',
      \ ], '\|') . '$'

function! s:relpath(dir, file) "{{{1
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
  if a:file =~# '\m/$'
    let result_path .= '/'
  endif
  return result_path
endfunction

"}}}1
