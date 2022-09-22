set nocompatible
set runtimepath^=~/.local/plugged/wiki.vim
set runtimepath^=~/.local/plugged/wiki-ft.vim
filetype plugin indent on
syntax enable

set noswapfile
set nomore
set foldlevel=99

nnoremap q :qall!<cr>

" let g:wiki_cache_persistent = 0

runtime plugin/wiki.vim

silent edit ~/.local/wiki/OpenConnect.wiki

if !empty($CLEAR)
  call wiki#cache#clear('graph')
endif

let s:t1 = wiki#debug#time()
let s:file = expand('%:p')
let s:graph = wiki#graph#builder#get()
let s:t1 = wiki#debug#time(s:t1, '__init__               ')

call s:graph.get_links_from(s:file)
let s:t1 = wiki#debug#time(s:t1, 'get_links_from         ')

call wiki#debug#profile_start()
call s:graph.get_links_to(s:file)
let s:t1 = wiki#debug#time(s:t1, 'get_links_to           ')
call wiki#debug#profile_stop()

call s:graph.get_links_to(s:file)
let s:t1 = wiki#debug#time(s:t1, 'get_links_to           ')

call s:graph.get_broken_links_from(s:file)
let s:t1 = wiki#debug#time(s:t1, 'get_broken_links_from  ')

call s:graph.get_broken_links_global()
let s:t1 = wiki#debug#time(s:t1, 'get_broken_links_global')

call s:graph.get_tree_to(s:file, -1)
let s:t1 = wiki#debug#time(s:t1, 'get_tree_to            ')

call s:graph.get_tree_from(s:file, -1)
call wiki#debug#time(s:t1, 'get_tree_from          ')

quitall!

" Timings: Before applying any performance tuning
"
" | method                  | cached | uncached |
" |-------------------------|-------:|---------:|
" | get_links_from          |  0.003 |    0.015 |
" | get_links_to            |  0.450 |   39.201 |
" | get_links_map           |  0.450 |   39.201 |
" | get_broken_links_global |  0.579 |   37.996 |
" | get_tree_to             |  0.563 |   38.285 |
" | get_tree_from           |  0.005 |    0.283 |
"
" Timings: After performance tuning and double caching
"
" | method                  | cached | uncached |
" |-------------------------|-------:|---------:|
" | get_links_from          |  0.002 |    0.025 |
" | get_links_to            |  0.001 |   44.433 |
" | get_broken_links_global |  0.645 |    0.660 |
" | get_tree_to             |  1.173 |    1.137 |
" | get_tree_from           |  0.406 |    0.375 |
"
