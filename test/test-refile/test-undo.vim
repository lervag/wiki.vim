source ../init.vim
runtime plugin/wiki.vim

" Refiling should create a single undo point in the source buffer. Use
" feedkeys() so that undo is synced between commands as in normal usage.

" Refile to another page
silent edit wiki-tmp/index.wiki
let s:original = getline(1, '$')
normal! 13G
call feedkeys(":silent call wiki#page#refile(#{target_page: 'target-1'})\<cr>", 'xt')
call assert_notequal(s:original, getline(1, '$'))
call assert_equal(1, undotree().seq_last)
silent undo
call assert_equal(s:original, getline(1, '$'))

" Refile within the same page
silent edit wiki-tmp/source-1.wiki
let s:original = getline(1, '$')
normal! 10G
call feedkeys(":silent call wiki#page#refile(#{"
      \ . "target_anchor: '#Tasks#Baz', target_relation: 'inside'})\<cr>", 'xt')
call assert_equal(
      \ readfile('wiki-tmp/ref-relation-inside-1.wiki'),
      \ getline(1, '$'))
call assert_equal(1, undotree().seq_last)
silent undo
call assert_equal(s:original, getline(1, '$'))

call wiki#test#finished()
