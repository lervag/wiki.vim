source ../init.vim

function MyFunction(text) abort
  return substitute(tolower(a:text), '\s\+', '-', 'g')
endfunction

let g:wiki_filetypes = ['md']
let g:wiki_link_extension = '.md'
let g:wiki_map_create_page = 'MyFunction'
let g:wiki_root = g:testroot . '/wiki-basic'

runtime plugin/wiki.vim

silent WikiIndex
call assert_equal(g:wiki_root . '/index.md', expand('%'))

silent call wiki#page#open('Test this stuff')
call assert_equal(g:wiki_root . '/test-this-stuff.md', expand('%'))

call wiki#test#finished()
