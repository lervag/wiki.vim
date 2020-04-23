source ../init.vim

function MyFunction(text) abort
  return substitute(tolower(a:text), '\s\+', '-', 'g')
endfunction

let g:wiki_filetypes = ['md']
let g:wiki_link_extension = '.md'
let g:wiki_map_create_page = 'MyFunction'
let g:wiki_root = expand('<sfile>:h') . '/ex1-basic'

runtime plugin/wiki.vim

silent WikiIndex
call wiki#test#assert_equal(g:wiki_root . '/index.md', expand('%'))

silent call wiki#page#open('Test this stuff')
call wiki#test#assert_equal(g:wiki_root . '/test-this-stuff.md', expand('%'))

if $QUIT | quitall! | endif
