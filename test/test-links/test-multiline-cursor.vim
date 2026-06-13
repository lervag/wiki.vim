source ../init.vim

runtime plugin/wiki.vim

" wiki#link#get() should detect a hard-wrapped markdown link from anywhere
" inside it, including the continuation line(s).
new
call setline(1, [
      \ 'A paragraph with a hard-wrapped [markdown',
      \ 'link](TargetPage) that continues here.',
      \])
setfiletype markdown

" Cursor on the first line, inside the description.
let s:link = wiki#link#get_at_pos(1, 35)
call assert_equal('md', s:link.type)
call assert_equal('TargetPage', s:link.url_raw)
call assert_equal('[markdown link](TargetPage)', s:link.content)
call assert_equal([1, 33], s:link.pos_start)
call assert_equal([2, 17], s:link.pos_end)

" Cursor on the continuation line, inside the url.
let s:link = wiki#link#get_at_pos(2, 8)
call assert_equal('md', s:link.type)
call assert_equal('TargetPage', s:link.url_raw)

" Cursor past the closing ')' is not part of the markdown link (it falls
" through to the catch-all 'word' type rather than extending the link).
call assert_equal('word', wiki#link#get_at_pos(2, 25).type)

" replace() collapses a multi-line link onto its first line.
call cursor(1, 35)
call wiki#link#get().replace('REPLACED')
call assert_equal('A paragraph with a hard-wrapped REPLACED that continues here.',
      \ getline(1))
call assert_equal(1, line('$'))

bwipeout!

" Hard-wrapped markdown image (md_fig).
new
call setline(1, [
      \ 'An image ![alt',
      \ 'text](Figure.png) here.',
      \])
setfiletype markdown
let s:link = wiki#link#get_at_pos(1, 12)
call assert_equal('md_fig', s:link.type)
call assert_equal('Figure.png', s:link.url_raw)
call assert_equal('![alt text](Figure.png)', s:link.content)
call assert_equal([1, 10], s:link.pos_start)
call assert_equal([2, 17], s:link.pos_end)
bwipeout!

" Hard-wrapped wiki link with a description.
new
call setline(1, [
      \ 'See [[Some Page|a wrapped',
      \ 'description]] now.',
      \])
let s:link = wiki#link#get_at_pos(2, 3)
call assert_equal('wiki', s:link.type)
call assert_equal('Some Page', s:link.url_raw)
call assert_equal('a wrapped description', s:link.text)
call assert_equal('[[Some Page|a wrapped description]]', s:link.content)
call assert_equal([1, 5], s:link.pos_start)
call assert_equal([2, 13], s:link.pos_end)
bwipeout!

" Hard-wrapped orgmode link with a description.
new
call setline(1, [
      \ 'Link [[TargetPage][a wrapped',
      \ 'description]] end.',
      \])
let s:link = wiki#link#get_at_pos(2, 3)
call assert_equal('org', s:link.type)
call assert_equal('TargetPage', s:link.url_raw)
call assert_equal('a wrapped description', s:link.text)
call assert_equal('[[TargetPage][a wrapped description]]', s:link.content)
call assert_equal([1, 6], s:link.pos_start)
call assert_equal([2, 13], s:link.pos_end)
bwipeout!

call wiki#test#finished()
