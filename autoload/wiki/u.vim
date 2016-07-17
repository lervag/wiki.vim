" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#u#escape(string) "{{{1
  return escape(a:string, '~.*[]\^$')
endfunction

"}}}1
function! wiki#u#in_syntax(name, ...) " {{{1
  let l:pos = [0, 0]
  let l:pos[0] = a:0 > 0 ? a:1 : line('.')
  let l:pos[1] = a:0 > 1 ? a:2 : col('.')
  if mode() ==# 'i'
    let l:pos[1] -= 1
  endif
  if l:pos[1] <= 0
    let l:pos[0] -= 1
    let l:pos[1] = 10000
  endif
  call map(l:pos, 'max([v:val, 1])')

  " Check syntax at position
  return match(map(synstack(l:pos[0], l:pos[1]),
        \          "synIDattr(v:val, 'name')"),
        \      '^' . a:name) >= 0
endfunction

" }}}1
function! wiki#u#is_code(...) " {{{1
  let l:lnum = a:0 > 0 ? a:1 : line('.')

  return match(map(synstack(l:lnum, 1),
          \        "synIDattr(v:val, 'name')"), '^wikiPre') > -1
endfunction

" }}}1
function! wiki#u#run_code_snippet() " {{{1
  let l:pos = getpos('.')
  let l:lnum1 = l:pos[1]
  let l:lnum2 = l:pos[1]
  if !wiki#u#is_code(l:lnum1) | return | endif

  while 1
    if !wiki#u#is_code(l:lnum1-1) | break | endif
    let l:lnum1 -= 1
  endwhile
  let l:lnum1 += 1

  while 1
    if !wiki#u#is_code(l:lnum2+1) | break | endif
    let l:lnum2 += 1
  endwhile
  let l:lnum2 -= 1

  let l:ft = matchstr(getline(l:lnum1-1), '^\s*```\zs\w\+')
  if empty(l:ft) | let l:ft = 'sh' | endif

  execute l:lnum1 . ',' . l:lnum2 . 'QuickRun' l:ft

  call setpos('.', l:pos)
endfunction

" }}}1

" vim: fdm=marker sw=2
