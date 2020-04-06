source init.vim

let g:wiki_link_target_map = 'MyFunction'

function MyFunction(text) abort
  return substitute(tolower(a:text), '\s\+', '-', 'g')
endfunction

runtime plugin/wiki.vim

" Test toggle normal on regular markdown links using wiki style links
silent edit ex1-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal(getline('.'), '[[this-is-a-wiki|This is a wiki]].')

" Test toggle normal on regular markdown links using wiki style links
normal! 5G
silent execute "normal V\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal(getline('.'), '[[createfulllinelink|CreateFullLineLink]]')

" Test toggle on multibyte character words
bwipeout!
silent edit ex1-basic/multibyte.wiki
normal! j
silent execute "normal \<Plug>(wiki-link-toggle)"
call wiki#test#assert_equal(getline('.'), '[[ウィキ]]')
normal! 5j
silent execute "normal \<Plug>(wiki-link-toggle)"
call wiki#test#assert_equal(getline('.'), '[[pokémon|Pokémon]]')

" Test toggle normal on regular markdown links using md style links
bwipeout!
let g:wiki_link_target_type = 'md'
silent edit ex1-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal(getline('.'), '[This is a wiki](this-is-a-wiki).')

" Test toggle normal on regular markdown links using md style links with the
" markdown extension
bwipeout!
let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = '.md'
silent edit ex1-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call wiki#test#assert_equal(getline('.'), '[This is a wiki](this-is-a-wiki.md).')

if $QUIT | quitall! | endif
