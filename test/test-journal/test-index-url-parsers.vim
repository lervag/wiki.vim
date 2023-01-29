source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'
let g:wiki_journal = {
      \ 'name': 'generalDiary',
      \}

runtime plugin/wiki.vim
silent call wiki#page#open('JournalIndex')

let g:wiki_journal_index.link_text_parser = { b, d, p -> d }
let g:wiki_journal_index.link_url_parser = { b, d, p ->
      \ wiki#paths#relative(wiki#get_root() . p, expand('%:h'))
      \}
WikiJournalIndex
call assert_equal(
      \ readfile('test-index-url-parsers.relurls.wiki'),
      \ getline(1, 15))

call wiki#test#finished()
