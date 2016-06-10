" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#opts#get(option, ...) "{{{1
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1

  if has_key(g:vimwiki_list[idx], a:option)
    let val = g:vimwiki_list[idx][a:option]
  elseif has_key(s:vimwiki_defaults, a:option)
    let val = s:vimwiki_defaults[a:option]
    let g:vimwiki_list[idx][a:option] = val
  else
    let val = b:vimwiki_list[a:option]
  endif

  return val
endfunction

"}}}1
function! vimwiki#opts#set(option, value, ...) "{{{1
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1

  if has_key(s:vimwiki_defaults, a:option) ||
        \ has_key(g:vimwiki_list[idx], a:option)
    let g:vimwiki_list[idx][a:option] = a:value
  elseif exists('b:vimwiki_list')
    let b:vimwiki_list[a:option] = a:value
  else
    let b:vimwiki_list = {}
    let b:vimwiki_list[a:option] = a:value
  endif
endfunction

"}}}1

" {{{1 Defaul wiki
let s:vimwiki_defaults = {}
let s:vimwiki_defaults.path = '~/vimwiki/'
let s:vimwiki_defaults.index = 'index'
let s:vimwiki_defaults.ext = '.wiki'
let s:vimwiki_defaults.maxhi = 0
let s:vimwiki_defaults.auto_export = 0
let s:vimwiki_defaults.auto_toc = 0
let s:vimwiki_defaults.temp = 0
let s:vimwiki_defaults.diary_rel_path = 'diary/'
let s:vimwiki_defaults.diary_index = 'diary'
let s:vimwiki_defaults.diary_header = 'Diary'
let s:vimwiki_defaults.diary_sort = 'desc'
let s:vimwiki_defaults.diary_link_fmt = '%Y-%m-%d'
let s:vimwiki_defaults.list_margin = -1
" }}}1
