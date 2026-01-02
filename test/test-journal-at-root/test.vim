source ../init.vim

let g:wiki_root = 'wiki'
let g:wiki_journal = {'name' : '', 'root': ''}
runtime plugin/wiki.vim

silent call wiki#journal#open()
call assert_true(b:wiki.in_journal)
let s:date = strftime(g:wiki_journal.date_format[g:wiki_journal.frequency])
call assert_equal(s:date, expand('%:t:r'))

WikiJournalPrev
call assert_equal('2019-04-02', expand('%:t:r'))

call wiki#test#finished()
