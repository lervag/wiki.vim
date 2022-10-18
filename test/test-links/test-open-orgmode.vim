source ../init.vim

function MyFunction(text) abort
  return substitute(tolower(a:text), '\s\+', '-', 'g')
endfunction

let g:wiki_filetypes = ['org']
let g:wiki_link_extension = '.org'
let g:wiki_map_create_page = 'MyFunction'
let g:wiki_root = g:testroot . '/wiki-basic'

runtime plugin/wiki.vim

silent WikiIndex
call assert_equal(g:wiki_root . '/index.org', expand('%'))

silent call wiki#page#open('Test this stuff')
call assert_equal(g:wiki_root . '/test-this-stuff.org', expand('%'))

call wiki#test#finished()
