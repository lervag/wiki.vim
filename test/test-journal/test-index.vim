source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'
runtime plugin/wiki.vim

silent call wiki#page#open('JournalIndex')
WikiJournalIndex

call assert_equal('## January', getline(4))
call assert_equal('## October', getline(76))

call wiki#test#finished()
