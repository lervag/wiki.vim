" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#complete#omnicomplete(findstart, base) " {{{1
  if a:findstart
    let l:line = getline('.')[:col('.')-2]

    return match(l:line,
          \     '\[\[\zs[^\\[\]]*$'
          \ . '\|\[.*\](\zs[^)]*$')
  else
    if a:base =~# '#'
      let l:segments = split(a:base, '#', 1)
      let l:base = join(l:segments[1:], '#')
      let l:link_info = vimwiki#link#parse(
            \ empty(l:segments[0])
            \   ? expand('%:t:r')
            \   : l:segments[0])

      return map(
            \   filter(s:get_anchors(l:link_info.filename),
            \     'v:val =~# ''^'' . vimwiki#u#escape(l:base)'),
            \   'l:segments[0] . ''#'' . v:val')
    else
      if len(a:base) > 0 && a:base[0] ==# '/'
        let l:cwd = resolve(g:vimwiki.root)
        let l:cands = map(globpath(l:cwd, '**/*.wiki', 0, 1),
              \ '''/'' . s:relpath(l:cwd, fnamemodify(v:val, '':r''))')
      else
        let l:cands = map(globpath(expand('%:p:h'), '**/*.wiki', 0, 1),
              \ 'resolve(fnamemodify(v:val, '':.:r''))')
      endif

      return filter(l:cands, 'v:val =~# ''^'' . vimwiki#u#escape(a:base)')
    endif
  endif
endfunction

" }}}1

function! s:get_anchors(filename) " {{{1
  if !filereadable(a:filename)
    return []
  endif

  let rxbold = g:vimwiki_markdown_bold_search
  let rxtag = g:vimwiki_markdown_tag_search

  let anchor_level = ['', '', '', '', '', '', '']
  let anchors = []
  let current_complete_anchor = ''
  for line in readfile(a:filename)

    " collect headers
    let h_match = matchlist(line, g:vimwiki.rx.header2)
    if !empty(h_match)
      let header = vimwiki#u#trim(h_match[2])
      let level = len(h_match[1])
      call add(anchors, header)
      let anchor_level[level-1] = header
      for l in range(level, 6)
        let anchor_level[l] = ''
      endfor
      if level == 1
        let current_complete_anchor = header
      else
        let current_complete_anchor = ''
        for l in range(level-1)
          if anchor_level[l] != ''
            let current_complete_anchor .= anchor_level[l].'#'
          endif
        endfor
        let current_complete_anchor .= header
        call add(anchors, current_complete_anchor)
      endif
    endif

    " collect bold text (there can be several in one line)
    let bold_count = 1
    while 1
      let bold_text = matchstr(line, rxbold, 0, bold_count)
      if bold_text == ''
        break
      endif
      call add(anchors, bold_text)
      if current_complete_anchor != ''
        call add(anchors, current_complete_anchor.'#'.bold_text)
      endif
      let bold_count += 1
    endwhile

    " collect tags text (there can be several in one line)
    let tag_count = 1
    while 1
      let tag_group_text = matchstr(line, rxtag, 0, tag_count)
      if tag_group_text == ''
        break
      endif
      for tag_text in split(tag_group_text, ':')
        call add(anchors, tag_text)
        if current_complete_anchor != ''
          call add(anchors, current_complete_anchor.'#'.tag_text)
        endif
      endfor
      let tag_count += 1
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
  if a:file =~ '\m/$'
    let result_path .= '/'
  endif
  return result_path
endfunction

"}}}1

" vim: fdm=marker sw=2
