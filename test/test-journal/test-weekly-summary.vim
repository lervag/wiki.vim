source ../init.vim

" This tests that the weekly journal summary gathers the contents of each daily
" entry, including the final block of a file that is not terminated by a blank
" line.

let s:root = tempname()
let g:wiki_root = s:root
let g:wiki_journal = {'root': s:root}
runtime plugin/wiki.vim

let s:dates = wiki#date#get_week_dates(2, 2019)
call mkdir(s:root, 'p')

" Monday: single block, no trailing blank line
call writefile([
      \ 'Project 1',
      \ '* I did this',
      \ '* And that',
      \], s:root . '/' . s:dates[0] . '.wiki')

" Tuesday: block followed directly by a section header (no blank line), and
" a same-titled block that should be merged into Monday's
call writefile([
      \ 'Project 1',
      \ '* I did more of this',
      \ '# Meeting notes',
      \ '* not part of the summary',
      \], s:root . '/' . s:dates[1] . '.wiki')

new
call wiki#template#weekly_summary('2019', '02')

let s:lines = getline(1, '$')

" The title is present
call assert_equal('# Summary, 2019 week 02', s:lines[0])

" Both daily entries are linked
call assert_notequal(-1, index(s:lines, 'journal:' . s:dates[0]))
call assert_notequal(-1, index(s:lines, 'journal:' . s:dates[1]))

" Monday's final (and only) block was captured despite no trailing blank line
call assert_notequal(-1, index(s:lines, '* I did this'))
call assert_notequal(-1, index(s:lines, '* And that'))

" Tuesday's block was captured despite being followed directly by a header,
" and it was merged under the shared "Project 1" title
call assert_notequal(-1, index(s:lines, '* I did more of this'))

" Content after the first section header is excluded
call assert_equal(-1, index(s:lines, '* not part of the summary'))
call assert_equal(-1, index(s:lines, '# Meeting notes'))

bwipeout!
call wiki#test#finished()
