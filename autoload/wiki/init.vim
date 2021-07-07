" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

" Note: This file is loaded as long as wiki.vim is loaded, so try to keep it as
"       short as possible!

function! wiki#init#option(name, default) abort " {{{1
  let l:option = 'g:' . a:name
  if !exists(l:option)
    let {l:option} = a:default
  elseif type(a:default) == type({})
    call wiki#u#extend_recursive({l:option}, a:default, 'keep')
  endif
endfunction

" }}}1
function! wiki#init#apply_mappings_from_dict(dict, arg) abort " {{{1
  for [l:rhs, l:lhs] in items(a:dict)
    if l:rhs[0] !=# '<'
      let l:mode = l:rhs[0]
      let l:rhs = l:rhs[2:]
    else
      let l:mode = 'n'
    endif

    if hasmapto(l:rhs, l:mode) || !empty(maparg(l:lhs, l:mode))
      continue
    endif

    execute l:mode . 'map <silent>' . a:arg l:lhs l:rhs
  endfor
endfunction

" }}}1
function! wiki#init#get_os() abort " {{{1
  if has('win32')
    return 'win'
  elseif has('unix')
    if has{'ios') || system('uname') =~# 'Darwin'
      return 'mac'
    else
      return 'linux'
    endif
  endif
endfunction

" }}}1
