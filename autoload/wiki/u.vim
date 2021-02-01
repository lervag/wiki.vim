" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#u#command(cmd) abort " {{{1
  return split(execute(a:cmd, 'silent!'), "\n")
endfunction

" }}}1
function! wiki#u#escape(string) abort "{{{1
  return escape(a:string, '~.*[]\^$')
endfunction

"}}}1
function! wiki#u#in_syntax(name, ...) abort " {{{1
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
function! wiki#u#is_code(...) abort " {{{1
  let l:lnum = a:0 > 0 ? a:1 : line('.')

  return match(map(synstack(l:lnum, 1),
          \        "synIDattr(v:val, 'name')"),
          \    '^\%(wikiPre\|mkd\%(Code\|Snippet\)\|markdownCode\)') > -1
endfunction

" }}}1
function! wiki#u#run_code_snippet() abort " {{{1
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
function! wiki#u#extend_recursive(dict1, dict2, ...) abort " {{{1
  let l:option = a:0 > 0 ? a:1 : 'force'
  if index(['force', 'keep', 'error'], l:option) < 0
    throw 'E475: Invalid argument: ' . l:option
  endif

  for [l:key, l:value] in items(a:dict2)
    if !has_key(a:dict1, l:key)
      let a:dict1[l:key] = l:value
    elseif type(l:value) == type({})
      call wiki#u#extend_recursive(a:dict1[l:key], l:value, l:option)
    elseif l:option ==# 'error'
      throw 'E737: Key already exists: ' . l:key
    elseif l:option ==# 'force'
      let a:dict1[l:key] = l:value
    endif
    unlet l:value
  endfor

  return a:dict1
endfunction

" }}}1
function! wiki#u#trim(str) abort " {{{1
  if exists('*trim') | return trim(a:str) | endif

  let l:str = substitute(a:str, '^\s*', '', '')
  let l:str = substitute(l:str, '\s*$', '', '')

  return l:str
endfunction

" }}}1
function! wiki#u#uniq_unsorted(list) abort " {{{1
  if len(a:list) <= 1 | return a:list | endif

  let l:visited = {}
  let l:result = []
  for l:x in a:list
    let l:key = string(l:x)
    if !has_key(l:visited, l:key)
      let l:visited[l:key] = 1
      call add(l:result, l:x)
    endif
  endfor

  return l:result
endfunction

" }}}1
