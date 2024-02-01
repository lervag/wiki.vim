source ../init.vim

let g:wiki_select_method = {
      \ 'pages': function('wiki#fzf#pages'),
      \ 'tags': function('wiki#fzf#tags'),
      \ 'toc': function('wiki#fzf#toc'),
      \ 'links': function('wiki#fzf#toc'),
      \}
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

WikiPages
