source ../init.vim

runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

normal! Go
let g:wiki_link_creation.wiki = #{
      \ link_type: 'wiki',
      \ url_extension: '',
      \}
call wiki#link#add('pageA', '')
call assert_equal('[[pageA]]', getline('.'))

normal! o
let g:wiki_link_creation.wiki.link_text = { url -> wiki#toc#get_page_title(url) }
call wiki#link#add('pageA', '')
call assert_equal('[[pageA|Section 1]]', getline('.'))

normal! o
let g:wiki_link_creation.wiki.link_text = { _ -> "hello there" }
call wiki#link#add('pageA', '')
call assert_equal('[[pageA|hello there]]', getline('.'))

call wiki#test#finished()
