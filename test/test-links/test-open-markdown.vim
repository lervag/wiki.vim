source ../init.vim

let g:wiki_filetypes = ['md']
let g:wiki_root = g:testroot . '/wiki-basic'

runtime plugin/wiki.vim

let g:wiki_link_creation.md.url_transform =
      \ { x -> substitute(tolower(x), '\s\+', '-', 'g') }

silent WikiIndex
call assert_equal(g:wiki_root . '/index.md', expand('%'))

silent call wiki#page#open('Test this stuff')
call assert_equal(g:wiki_root . '/test-this-stuff.md', expand('%'))

call wiki#test#finished()
