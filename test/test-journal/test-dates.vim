source ../init.vim
let g:wiki_root = g:testroot . '/wiki-basic'
runtime plugin/wiki.vim

let g:wiki_journal.date_format = {
      \ 'daily': '%d.%m.%Y',
      \ 'weekly': '%Y/w%V',
      \ 'monthly': '%Y/m%m',
      \}


call assert_equal(['15.10.2022', 'daily'], wiki#journal#date_to_node('2022-10-15'))
call assert_equal(['2022/w40', 'weekly'], wiki#journal#date_to_node('2022-w40'))
call assert_equal(['2022/m10', 'monthly'], wiki#journal#date_to_node('2022-10'))

call assert_equal(['2022-10-15', 'daily'], wiki#journal#node_to_date('15.10.2022'))
call assert_equal(['2022-w40', 'weekly'], wiki#journal#node_to_date('2022/w40'))
call assert_equal(['2022-10', 'monthly'], wiki#journal#node_to_date('2022/m10'))
call assert_equal(['', ''], wiki#journal#node_to_date())
silent call wiki#journal#open()
call assert_equal([strftime('%Y-%m-%d'), 'daily'], wiki#journal#node_to_date())
bwipeout!

call assert_equal('2022-10-01', wiki#journal#get_next_date('2022-09-30', 'daily'))
call assert_equal('2023-01-01', wiki#journal#get_next_date('2022-12-31', 'daily'))
call assert_equal('2022-w52', wiki#journal#get_next_date('2022-w51', 'weekly'))
call assert_equal('2023-w01', wiki#journal#get_next_date('2022-w52', 'weekly'))
call assert_equal('2020-w53', wiki#journal#get_next_date('2020-w52', 'weekly'))
call assert_equal('2023-01', wiki#journal#get_next_date('2022-12', 'monthly'))
call assert_equal('2020-05', wiki#journal#get_next_date('2020-04', 'monthly'))


call wiki#test#finished()
