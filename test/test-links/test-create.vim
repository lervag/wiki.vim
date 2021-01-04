source ../init.vim

let g:wiki_map_link_create = 'MyFunction'

function MyFunction(text) abort
  return substitute(tolower(a:text), '\s\+', '-', 'g')
endfunction

runtime plugin/wiki.vim

" Test toggle normal on regular markdown links using wiki style links
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal('[[this-is-a-wiki|This is a wiki]].', getline('.'))

" Test toggle normal on regular markdown links using wiki style links
normal! 5G
silent execute "normal V\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal('[[createfulllinelink|CreateFullLineLink]]', getline('.'))

" Test toggle on multibyte character words
bwipeout!
silent edit ../wiki-basic/multibyte.wiki
normal! j
silent execute "normal \<Plug>(wiki-link-toggle)"
call wiki#test#assert_equal('[[ウィキ]]', getline('.'))
normal! 5j
silent execute "normal \<Plug>(wiki-link-toggle)"
call wiki#test#assert_equal('[[pokémon|Pokémon]]', getline('.'))

" Test toggle normal on regular markdown links using md style links
bwipeout!
let g:wiki_link_target_type = 'md'
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal('[This is a wiki](this-is-a-wiki).', getline('.'))

" Test toggle normal on regular markdown links using md style links with the
" markdown extension
bwipeout!
let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = '.md'
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal('[This is a wiki](this-is-a-wiki.md).', getline('.'))

" Test toggle normal on regular markdown links using md style links in journal
bwipeout!
let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = ''
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute 'let b:wiki.in_journal=1'
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal('[This is a wiki](/this-is-a-wiki).', getline('.'))

" Test toggle normal on regular markdown links using md style links in journal
" without `g:wiki_map_link_create`
bwipeout!
let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = ''
let g:wiki_map_link_create = ''
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute 'let b:wiki.in_journal=1'
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal('[This is a wiki](/This is a wiki).', getline('.'))

if $QUIT | quitall! | endif
