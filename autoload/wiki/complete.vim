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
      let l:pre_base = join(s:ctx.pre_anch, '#')
      if !empty(l:pre_base)
        let l:pre_base .= '#'
      endif
      let l:cnum = strlen(l:pre_base)
      let l:anchors = filter(s:get_anchors(l:url.path),
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

function! s:get_anchors(filename) " {{{1
  if !filereadable(a:filename)
    return []
  endif

  let anchor_level = ['', '', '', '', '', '', '']
  let anchors = []
  let current_complete_anchor = ''
  let preblock = 0
  for line in readfile(a:filename)
    " Ignore fenced code blocks
    if line =~# '^\s*```'
      let l:preblock += 1
    endif
    if l:preblock % 2 | continue | endif

    " Collect headers
    let h_match = matchlist(line, wiki#rx#header_items())
    if !empty(h_match)
      let header = h_match[2]
      let level = len(h_match[1])
      let anchor_level[level-1] = header
      for l in range(level, 6)
        let anchor_level[l] = ''
      endfor
      if level == 1
        let current_complete_anchor = header
        call add(anchors, header)
      else
        let current_complete_anchor = ''
        for l in range(level-1)
          if !empty(anchor_level[l])
            let current_complete_anchor .= anchor_level[l] . '#'
          endif
        endfor
        let current_complete_anchor .= header
        call add(anchors, current_complete_anchor)
      endif
      continue
    endif

    "
    " Collect bold text (there can be several in one line)
    "
    let l:count = 0
    while 1
      let l:count += 1
      let l:text = matchstr(line, wiki#rx#bold(), 0, l:count)
      if empty(l:text) | break | endif

      if !empty(current_complete_anchor)
        call add(anchors, current_complete_anchor . '#' . l:text[1:-2])
      endif
    endwhile
  endfor

  return anchors
endfunction

" }}}1
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
