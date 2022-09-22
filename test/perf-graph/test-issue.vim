set nocompatible
set runtimepath^=~/.local/plugged/wiki.vim
set runtimepath^=~/.local/plugged/wiki-ft.vim
filetype plugin indent on
syntax enable

set noswapfile
set nomore
set foldlevel=99

nnoremap q :qall!<cr>

let s:file = '/home/lervag/.cache/wiki.vim/links-out%home%lervag%.local%wiki.json'
echo 'cache exists pre: ' (filereadable(s:file) ? 'true' : 'false')

runtime plugin/wiki.vim

silent edit ~/.local/wiki/OpenConnect.wiki

let s:cache = wiki#cache#open('links-out', {
      \ 'local': 1,
      \ 'default': { 'ftime': -1, 'links': [] },
      \})

echo 'cache exists post:' (filereadable(s:file) ? 'true' : 'false')

quitall!

" Test 2:
" Sjekking mot cache viste at det noen ganger kommer inn ting i data med tomt
" filnavn. Det går fint å skrive til fil, men det går ikke fint å lese med
" json_decode!

" Test 1:
" cache exists pre:  true
" cache exists post: false
" cache name:  links-out%home%lervag%.local%wiki
" cache path:  /home/lervag/.cache/wiki.vim/links-out%home%lervag%.local%wiki.json
" cache ftime: -1
" cache size:  2
" item ftime:  -1
" item size:   0
" file ftime:  1662639404%
"     let s:cache = '/home/lervag/.cache/wiki.vim/links-out%home%lervag%.local%wiki.json'
"     echo 'cache exists pre: ' (filereadable(s:cache) ? 'true' : 'false')
"
"     runtime plugin/wiki.vim
"
"     silent edit ~/.local/wiki/OpenConnect.wiki
"
"     let s:graph = wiki#graph#builder#get()
"     echo 'cache exists post:' (filereadable(s:cache) ? 'true' : 'false')
"
"     let s:file = expand('%:p')
"     let s:current = s:graph.cache_links_out.get(s:file)
"
"     echo 'cache name: ' s:graph.cache_links_out.name
"     echo 'cache path: ' s:graph.cache_links_out.path
"     echo 'cache ftime:' s:graph.cache_links_out.ftime
"     echo 'cache size: ' len(s:graph.cache_links_out.data)
"     echo 'item ftime: ' s:current.ftime
"     echo 'item size:  ' len(s:current.links)
"     echo 'file ftime: ' getftime(s:file)
