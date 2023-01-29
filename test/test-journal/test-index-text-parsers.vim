source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'
let g:wiki_journal = {
      \ 'name': 'generalDiary',
      \}

runtime plugin/wiki.vim
silent call wiki#page#open('JournalIndex')

" The journal: scheme does not work well when there are multiple entries per
" date! This test more or less verifies this fact.
let g:wiki_journal_index.use_journal_scheme = v:true
let g:wiki_journal_index.link_text_parser = { b, d, p -> d }
WikiJournalIndex
call assert_equal(
      \ readfile('test-index-text-parsers.isodate-schemed.wiki'),
      \ getline(1, 15))

normal! ggdG
let g:wiki_journal_index.use_journal_scheme = v:false
let g:wiki_journal_index.link_text_parser = { b, d, p -> d }
WikiJournalIndex
call assert_equal(
      \ readfile('test-index-text-parsers.isodate.wiki'),
      \ getline(1, 15))

normal! ggdG
let g:wiki_journal_index.link_text_parser = { b, d, p -> b }
WikiJournalIndex
call assert_equal(
      \ readfile('test-index-text-parsers.basename.wiki'),
      \ getline(1, 15))

normal! ggdG
let g:wiki_journal_index.link_text_parser = { b, d, p ->
      \ wiki#toc#get_page_title(p) }
WikiJournalIndex
call assert_equal(
      \ readfile('test-index-text-parsers.header.wiki'),
      \ getline(1, 15))

normal! ggdG
unlet! g:wiki_journal_index.link_text_parser
function! g:wiki_journal_index.link_text_parser(base, date, path) dict
  let l:title = wiki#toc#get_page_title(a:path)
  return a:date . ': ' . l:title
endfunction
WikiJournalIndex
call assert_equal(
      \ readfile('test-index-text-parsers.date-header.wiki'),
      \ getline(1, 15))

call wiki#test#finished()
