" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#u#escape(string) "{{{1
  return escape(a:string, '~.*[]\^$')
endfunction

"}}}1
function! vimwiki#u#in_syntax(name, ...) " {{{1
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
function! vimwiki#u#is_code(...) " {{{1
  let l:lnum = a:0 > 0 ? a:1 : line('.')

  return match(map(synstack(l:lnum, 1),
          \        "synIDattr(v:val, 'name')"), '^wikiPre') > -1
endfunction

" }}}1

" vim: fdm=marker sw=2
