source ../init.vim

let g:wiki_cache_persistent = 0
let g:wiki_filetypes = ['md']
let g:wiki_link_extension = '.md'
let g:wiki_link_target_type = 'md'
filetype plugin indent on

runtime plugin/wiki.vim

silent edit ../wiki-markdown/index.md
let s:candidates = wiki#test#completion('](', 'li')
call wiki#test#assert_equal(2, len(s:candidates))

silent edit ../wiki-markdown/subwiki/index.md
let s:candidates = wiki#test#completion('](/', 'in')
call wiki#test#assert_equal(2, len(s:candidates))
call wiki#test#assert_equal('/index.md', s:candidates[0].word)

if $QUIT | quitall! | endif
