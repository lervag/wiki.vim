source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'
let g:wiki_journal = {
      \ 'name': 'generalDiary',
      \}
runtime plugin/wiki.vim

silent call wiki#journal#open('2023-01-22')
call assert_true(b:wiki.in_journal)

silent call wiki#journal#go(2)
call assert_equal('2023-01-23_a', expand('%:t:r'))

silent call wiki#journal#go(2)
call assert_equal('2023-01-23_c', expand('%:t:r'))

silent call wiki#journal#go(-1)
call assert_equal('2023-01-23_b', expand('%:t:r'))

call wiki#test#finished()
