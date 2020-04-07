source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/BadName.wiki

silent call wiki#page#rename('GoodName')
call wiki#test#assert_equal('GoodName.wiki', expand('%:t'))
call wiki#test#assert_equal('[[GoodName]]', readfile('wiki-tmp/index.wiki')[4])

if $QUIT | quitall! | endif
