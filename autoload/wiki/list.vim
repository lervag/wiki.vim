" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#list#get_current() abort "{{{1
  let l:result = []
  let l:save_pos = getcurpos()

  let l:cnum_last = 10000000
  let [l:lnum, l:cnum] = searchpos(s:re_list_start, 'Wbcn')
  while l:lnum > 0 && l:cnum < l:cnum_last
    call add(l:result, s:parse_list_type(l:lnum, l:cnum))

    let l:cnum_last = l:cnum
    call setpos('.', [0, l:lnum, l:cnum, 0])
    let [l:lnum, l:cnum] = searchpos(s:re_list_start, 'Wbn')
  endwhile

  call setpos('.', l:save_pos)
  return l:result
endfunction

" }}}1
function! wiki#list#toggle() abort "{{{1
  let l:list = get(wiki#list#get_current(), 0, {})
  if empty(l:list) | return | endif

  call s:toggle_{l:list.type}(l:list)
endfunction

" }}}1

function! wiki#list#new_line_bullet() abort "{{{1
  let l:re = '\v^\s*[*-] %(TODO:)?\s*'
  let l:line = getline('.')

  " Toggle TODO if at start of list item
  if match(l:line, l:re . '$') >= 0
    let l:re = '\v^\s*[*-] \zs%(TODO:)?\s*'
    return repeat("\<bs>", strlen(matchstr(l:line, l:re)))
          \ . (match(l:line, 'TODO') < 0 ? 'TODO: ' : '')
  endif

  " Find last used bullet type (including the TODO)
  let l:lnum = search(l:re, 'bn')
  let l:bullet = matchstr(getline(l:lnum), l:re)

  " Return new line (unless current line is empty) and the correct bullet
  return (match(l:line, '^\s*$') >= 0 ? '' : "\<cr>") . "0\<c-d>" . l:bullet
endfunction

" }}}1

let s:re_list_start = '^\s*\zs[*-]'
let s:re_list_checkbox = '\[[ x]\]'
let s:re_list_checkbox_checked = '\[x\]'

function! s:parse_list_type(lnum, cnum) abort " {{{1
  let l:list = {
        \ 'lnum' : a:lnum,
        \ 'cnum' : a:cnum,
        \ 'type' : 'standard',
        \}

  let l:line = getline(a:lnum)
  if match(l:line, s:re_list_start . ' TODO:') >= 0
    let l:list.type = 'todo'
  elseif match(l:line, s:re_list_start . ' ' . s:re_list_checkbox) >= 0
    let l:list.type = 'checkbox'
    let l:list.checked = match(l:line,
          \ s:re_list_start . ' ' . s:re_list_checkbox_checked) >= 0
  endif

  return l:list
endfunction

" }}}1

function! s:toggle_standard(list) abort "{{{1
  let l:line = getline(a:list.lnum)
  let l:parts = split(l:line, s:re_list_start . ' \zs\s*\ze')
  call setline(a:list.lnum, l:parts[0] . 'TODO: ' . get(l:parts, 1, ''))
endfunction

" }}}1
function! s:toggle_todo(list) abort "{{{1
  let l:line = substitute(getline(a:list.lnum),
        \ s:re_list_start . ' \zsTODO:\s*\ze', '', '')
  call setline(a:list.lnum, l:line)
endfunction

" }}}1
function! s:toggle_checkbox(list) abort "{{{1
  if a:list.checked
    let l:line = substitute(getline(a:list.lnum),
          \ s:re_list_start . ' \[\zsx\ze\]', ' ', '')
  else
    let l:line = substitute(getline(a:list.lnum),
          \ s:re_list_start . ' \[\zs \ze\]', 'x', '')
  endif
  call setline(a:list.lnum, l:line)
endfunction

" }}}1

" vim: fdm=marker sw=2
