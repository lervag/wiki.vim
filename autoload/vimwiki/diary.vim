" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#diary#make_note(...) " {{{1
  let l:date = (a:0 > 0 ? a:1 : strftime('%Y-%m-%d'))
  call vimwiki#url#parse('diary:' . l:date).open()
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

  call vimwiki#diary#go(1)
endfunction

" }}}1
function! vimwiki#diary#go(step) " {{{1
  let l:links = s:get_links()
  let l:index = index(l:links, expand('%:t:r'))
  let l:target = l:index + a:step

  if l:target >= len(l:links) || l:target <= 0
    return
  endif

  call vimwiki#url#parse('diary:' . l:links[l:target]).open()
endfunction

" }}}1

function! s:get_links() " {{{1
  let l:links = filter(map(glob(g:vimwiki.diary . '*.wiki', 0, 1),
        \   'fnamemodify(v:val, '':t:r'')'),
        \ 'v:val =~# ''^\d\{4}-\d\d-\d\d''')

  for l:cand in [
        \ strftime('%Y-%m-%d'),
        \ expand('%:r'),
        \]
    if l:cand =~# '^\d\{4}-\d\d-\d\d'
          \ && index(l:links, l:cand) == -1
      call add(l:links, l:cand)
      let l:sort = 1
    endif
  endfor

  return get(l:, 'sort', 0) ? sort(l:links) : l:links
endfunction

" }}}1

" vim: fdm=marker sw=2
