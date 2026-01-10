source ../init.vim

runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

normal! Go
let g:wiki_link_creation.wiki = #{
      \ link_type: 'md',
      \ url_extension: '',
      \}
let s:target = fnamemodify('../wiki-basic/pageA.wiki', ':p')
call wiki#link#add(s:target, '')
call assert_equal('[pageA](pageA)', getline('.'))

normal! o
let g:wiki_link_creation.wiki = #{
      \ link_type: 'wiki',
      \ url_extension: '',
      \}
call wiki#link#add(s:target, '')
call assert_equal('[[pageA]]', getline('.'))

normal! o
let g:wiki_link_creation.wiki.link_text = { url -> wiki#toc#get_page_title(url) }
call wiki#link#add(s:target, '')
call assert_equal('[[pageA|Section 1]]', getline('.'))

normal! o
let g:wiki_link_creation.wiki.link_text = { _ -> "hello there" }
call wiki#link#add(s:target, '')
call assert_equal('[[pageA|hello there]]', getline('.'))

bwipeout!
silent edit ../wiki-basic/journal/2019-01-03.wiki
let g:wiki_link_creation.wiki = #{
      \ link_type: 'wiki',
      \ url_extension: '',
      \}
let s:target = fnamemodify('../wiki-basic/sub/Foo.wiki', ':~')
call wiki#link#add(s:target, '', #{text: 'Description'})
call assert_equal('[[/sub/Foo|Description]]', getline('.'))

normal! o
let g:wiki_link_creation.wiki.path_transform = { x ->
      \  fnamemodify(
      \    wiki#paths#relative(x, expand('%:p:h')),
      \    ':r'
      \  )
      \}
call wiki#link#add(s:target, '', #{text: 'Text'})
call assert_equal('[[../sub/Foo|Text]]', getline('.'))

call wiki#test#finished()
