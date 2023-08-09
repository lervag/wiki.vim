source ../init.vim

let g:wiki_select_method = {
      \ 'pages': function('wiki#fzf#pages'),
      \}
runtime plugin/wiki.vim

silent edit ../wiki-basic/index.wiki

WikiPages
WikiToc
