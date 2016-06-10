" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#opts#get(option) "{{{1
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

" {{{1 Defaul wiki
let s:vimwiki = {}
let s:vimwiki.path = '~/vimwiki/'
let s:vimwiki.index = 'index'
let s:vimwiki.ext = '.wiki'
let s:vimwiki.maxhi = 0
let s:vimwiki.auto_export = 0
let s:vimwiki.auto_toc = 0
let s:vimwiki.temp = 0
let s:vimwiki.diary_rel_path = 'diary/'
let s:vimwiki.diary_index = 'diary'
let s:vimwiki.diary_header = 'Diary'
let s:vimwiki.diary_sort = 'desc'
let s:vimwiki.diary_link_fmt = '%Y-%m-%d'
let s:vimwiki.list_margin = -1
" }}}1
