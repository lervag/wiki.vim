source ../init.vim

runtime plugin/wiki.vim

" Specify url transformer
let g:wiki_link_creation._.url_transform =
      \ { x -> substitute(tolower(x), '\s\+', '-', 'g') }

" Test transform normal on regular markdown links using wiki style links
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-transform-visual)"
call assert_equal('[[this-is-a-wiki|This is a wiki]].', getline('.'))

" Test transform normal on regular markdown links using wiki style links
normal! 5G
silent execute "normal V\<Plug>(wiki-link-transform-visual)"
call assert_equal('[[createfulllinelink|CreateFullLineLink]]', getline('.'))

" Test transform on multibyte character words
bwipeout!
silent edit ../wiki-basic/multibyte.wiki
normal! j
silent execute "normal \<Plug>(wiki-link-transform)"
call assert_equal('[[ウィキ]]', getline('.'))
normal! 5j
silent execute "normal \<Plug>(wiki-link-transform)"
call assert_equal('[[pokémon|Pokémon]]', getline('.'))

" Test transform normal on regular markdown links using md style links
bwipeout!
let g:wiki_link_creation._.link_type = 'md'
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-transform-visual)"
call assert_equal('[This is a wiki](this-is-a-wiki).', getline('.'))

" Test transform normal on regular markdown links using md style links with the
" markdown extension
bwipeout!
let g:wiki_link_creation._.url_extension = '.md'
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-transform-visual)"
call assert_equal('[This is a wiki](this-is-a-wiki.md).', getline('.'))
normal! 12G
silent execute "normal \<Plug>(wiki-link-transform)"
call assert_equal('[TestSubDirLink/](testsubdirlink/)', getline('.'))

" Test transform normal on regular orgmode links using md style links with the
" orgmode extension
bwipeout!
let g:wiki_link_creation._.link_type = 'org'
let g:wiki_link_creation._.url_extension = '.org'
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-transform-visual)"
call assert_equal('[[this-is-a-wiki.org][This is a wiki]].', getline('.'))
normal! 12G
silent execute "normal \<Plug>(wiki-link-transform)"
call assert_equal('[[testsubdirlink/][TestSubDirLink/]]', getline('.'))

" Test transform normal on regular markdown links using md style links in journal
bwipeout!
let g:wiki_link_creation._.link_type = 'md'
let g:wiki_link_creation._.url_extension = ''
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute 'let b:wiki.in_journal=1'
silent execute "normal vt.\<Plug>(wiki-link-transform-visual)"
call assert_equal('[This is a wiki](this-is-a-wiki).', getline('.'))

" Test transform normal on regular markdown links using md style links in journal
" without url transformer
bwipeout!
unlet g:wiki_link_creation._.url_transform
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute 'let b:wiki.in_journal=1'
silent execute "normal vt.\<Plug>(wiki-link-transform-visual)"
call assert_equal('[This is a wiki](This is a wiki).', getline('.'))

call wiki#test#finished()
