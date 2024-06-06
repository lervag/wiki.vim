source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'
runtime plugin/wiki.vim

let g:wiki_journal_index.reverse = v:true

silent call wiki#page#open('JournalIndex')
WikiJournalIndex
call assert_equal('# 2021', getline(2))
call assert_equal('## December', getline(4))
call assert_equal('## March', getline(76))
call assert_equal('[[journal:2021-12-27|2021-12-27]]', getline(6))

call wiki#test#finished()
