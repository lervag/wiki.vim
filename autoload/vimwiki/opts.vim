" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#opts#get(option) "{{{1
  if !exists('g:vimwiki')
    let g:vimwiki = {}
  endif

  return get(g:vimwiki, a:option,
        \ get(s:vimwiki, a:option,
        \ get(get(b:, 'vimwiki', {}), a:option)))
endfunction

"}}}1
function! vimwiki#opts#set(option, value) "{{{1
  if has_key(s:vimwiki, a:option) ||
        \ has_key(g:vimwiki, a:option)
    let g:vimwiki[a:option] = a:value
  elseif exists('b:vimwiki')
    let b:vimwiki[a:option] = a:value
  else
    let b:vimwiki = { a:option : a:value }
  endif
endfunction

"}}}1

"
" Defaul wiki
"
let s:vimwiki = {}
let s:vimwiki.path = fnamemodify('~/documents/wiki', ':p')
let s:vimwiki.maxhi = 0
let s:vimwiki.auto_export = 0
let s:vimwiki.auto_toc = 0
let s:vimwiki.temp = 0
let s:vimwiki.list_margin = -1

