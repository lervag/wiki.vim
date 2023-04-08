source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'
runtime plugin/wiki.vim

" Specify root directory and do some of the same tests as before
let g:wiki_journal.root = g:testroot . '/wiki-basic/diary'

silent call wiki#journal#open()
call assert_true(b:wiki.in_journal)
let s:date = strftime(g:wiki_journal.date_format[g:wiki_journal.frequency])
call assert_equal(s:date, expand('%:t:r'))

silent call wiki#journal#go(-2)
call assert_equal('2019-02-01', expand('%:t:r'))


let g:wiki_journal.root = g:testroot . '/wiki-diary'

silent call wiki#journal#open()
call assert_true(b:wiki.in_journal)
let s:date = strftime(g:wiki_journal.date_format[g:wiki_journal.frequency])
call assert_equal(s:date, expand('%:t:r'))

silent call wiki#journal#go(-1)
call assert_equal('2019-04-02', expand('%:t:r'))


call wiki#test#finished()
