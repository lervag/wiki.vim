source ../init.vim

runtime plugin/wiki.vim

" Test transform normal on regular markdown links using wiki style links
silent edit ../wiki-basic/index.wiki
7WikiLinkExtractHeader
call assert_equal('[[NewPage|This page is new]]', getline(7))

silent edit!
execute "normal ggV10j\<plug>(wiki-link-extract-header)"
call assert_equal('[[NewPage|This page is new]]', getline(7))
call assert_equal('[[/sub/Foo|Foo]]', getline(9))

call wiki#test#finished()
