source ../init.vim

let g:wiki_map_text_to_link = 'TextToLink'

function TextToLink(text) abort
  return [substitute(tolower(a:text), '\s\+', '-', 'g'), a:text]
endfunction

runtime plugin/wiki.vim

" Test toggle normal on regular markdown links using wiki style links
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[[this-is-a-wiki|This is a wiki]].', getline('.'))

" Test toggle normal on regular markdown links using wiki style links
normal! 5G
silent execute "normal V\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[[createfulllinelink|CreateFullLineLink]]', getline('.'))

" Test toggle on multibyte character words
bwipeout!
silent edit ../wiki-basic/multibyte.wiki
normal! j
silent execute "normal \<Plug>(wiki-link-toggle)"
call assert_equal('[[ウィキ]]', getline('.'))
normal! 5j
silent execute "normal \<Plug>(wiki-link-toggle)"
call assert_equal('[[pokémon|Pokémon]]', getline('.'))

" Test toggle normal on regular markdown links using md style links
bwipeout!
let g:wiki_link_target_type = 'md'
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[This is a wiki](this-is-a-wiki).', getline('.'))

" Test toggle normal on regular markdown links using md style links with the
" markdown extension
bwipeout!
let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = '.md'
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[This is a wiki](this-is-a-wiki.md).', getline('.'))
normal! 12G
silent execute "normal \<Plug>(wiki-link-toggle)"
call assert_equal('[TestSubDirLink/](testsubdirlink/)', getline('.'))

" Test toggle normal on regular orgmode links using md style links with the
" orgmode extension
bwipeout!
let g:wiki_link_target_type = 'org'
let g:wiki_link_extension = '.org'
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[[this-is-a-wiki.org][This is a wiki]].', getline('.'))
normal! 12G
silent execute "normal \<Plug>(wiki-link-toggle)"
call assert_equal('[[testsubdirlink/][TestSubDirLink/]]', getline('.'))

" Test toggle normal on regular markdown links using md style links in journal
bwipeout!
let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = ''
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute 'let b:wiki.in_journal=1'
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[This is a wiki](this-is-a-wiki).', getline('.'))

" Test toggle normal on regular markdown links using md style links in journal
" without `g:wiki_map_text_to_link`
bwipeout!
let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = ''
let g:wiki_map_text_to_link = ''
silent edit ../wiki-basic/index.wiki
normal! 3G
silent execute 'let b:wiki.in_journal=1'
silent execute "normal vt.\<Plug>(wiki-link-toggle-visual)"
call assert_equal('[This is a wiki](This is a wiki).', getline('.'))

bwipeout!
let g:wiki_link_target_type = 'md'
let g:wiki_link_extension = ''
let g:wiki_map_text_to_link = 'TextToLink2'
function TextToLink2(text) abort
  return [a:text, substitute(a:text, '-', ' ', 'g')]
endfunction
silent edit ../wiki-basic/index.wiki
normal! 14G
silent execute 'normal glt.'
call assert_equal('[This is a wiki](This-is-a-wiki).', getline('.'))

call wiki#test#finished()
