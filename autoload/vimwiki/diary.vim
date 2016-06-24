" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#diary#make_note(...) " {{{1
  call vimwiki#link#open('edit',
        \ 'diary:' . (a:0 > 0 ? a:1 : strftime('%Y-%m-%d')))
endfunction

" }}}1
function! vimwiki#diary#copy_note() " {{{1
  let l:current = expand('%:t:r')

  " Get next weekday
  let l:candidate = systemlist('date -d "' . l:current . ' +1 day" +%F')[0]
  while systemlist('date -d "' . l:candidate . '" +%u')[0] > 5
    let l:candidate = systemlist('date -d "' . l:candidate . ' +1 day" +%F')[0]
  endwhile

  let l:next = expand('%:p:h') . '/' . l:candidate . '.wiki'
  if !filereadable(l:next)
    execute 'write' l:next
  endif

  call vimwiki#diary#goto_next_day()
endfunction

" }}}1
function! vimwiki#diary#goto_next_day() "{{{
  let [l:index, l:entries] = s:get_position_links(expand('%:t:r'))

  if l:index == (len(l:entries) - 1)
    return
  endif

  if l:index != -1 && l:index < len(l:entries) - 1
    let l:link = 'diary:' . l:entries[l:index+1]
  else
    let l:link = 'diary:' . strftime('%Y-%m-%d')
  endif

  call vimwiki#link#open('edit ', l:link)
endfunction "}}}
function! vimwiki#diary#goto_prev_day() "{{{
  let [l:index, l:entries] = s:get_position_links(expand('%:t:r'))

  if l:index == 0
    return
  endif

  if l:index > 0
    let l:link = 'diary:' . l:entries[l:index-1]
  else
    let l:link = 'diary:' . strftime('%Y-%m-%d')
  endif

  call vimwiki#link#open('edit ', l:link)
endfunction "}}}

function! s:get_position_links(link) " {{{1
  let idx = -1
  let links = []
  if a:link =~# '^\d\{4}-\d\d-\d\d'
    let links = keys(s:get_diary_links())
    if index(links, strftime('%Y-%m-%d')) == -1
      call add(links, strftime('%Y-%m-%d'))
    endif
    call sort(links)
    let idx = index(links, a:link)
  endif
  return [idx, links]
endfunction

" }}}1
function! s:get_diary_links() " {{{1
  let rx = '^\d\{4}-\d\d-\d\d'
  let files = split(glob(g:vimwiki.diary . '*.wiki'), '\n')
  call filter(files, 'fnamemodify(v:val, ":t") =~# "'.escape(rx, '\').'"')

  let links_with_captions = s:read_captions(files)

  return links_with_captions
endfunction

" }}}1
function! s:read_captions(files) " {{{1
  let result = {}
  for fl in a:files
    let fl_key = fnamemodify(fl, ':t:r')

    if filereadable(fl)
      for line in readfile(fl, '', 5)
        if line =~# g:vimwiki.rx.header && !has_key(result, fl_key)
          let result[fl_key] = vimwiki#u#trim(matchstr(line, g:vimwiki.rx.header))
        endif
      endfor
    endif

    if !has_key(result, fl_key)
      let result[fl_key] = ''
    endif

  endfor
  return result
endfunction

" }}}1

" vim: fdm=marker sw=2
