source ../init.vim

runtime plugin/wiki.vim

" Links that are hard-wrapped across two lines should still be detected by the
" bulk extraction path (used by e.g. WikiGraphCheckLinks).
let s:lines = [
      \ '# Multi-line links',
      \ '',
      \ 'This is a paragraph with a hard-wrapped [markdown',
      \ 'link](TargetPage) that spans two lines.',
      \ '',
      \ 'And a wiki link [[Some',
      \ 'Page]] also wrapped here.',
      \ '',
      \ 'An orgmode link [[OrgTarget][org',
      \ 'description]] wrapped too.',
      \ '',
      \ 'An image ![figure',
      \ 'caption](Image.png) wrapped.',
      \ '',
      \ '```',
      \ 'A fenced code block with a [wrapped',
      \ 'link](ShouldBeIgnored) must not be detected.',
      \ '```',
      \ '',
      \ 'A trailing single-line [normal link](OtherPage) for good measure.',
      \]
let s:links = wiki#link#get_all_from_lines(s:lines, '/tmp/multiline.wiki')

" The four wrapped links and the trailing single-line link are found; the link
" inside the fenced code block is skipped.
call assert_equal(5, len(s:links))

" Wrapped markdown link: [markdown\nlink](TargetPage)
call assert_equal('md', s:links[0].type)
call assert_equal('TargetPage', s:links[0].url_raw)
call assert_equal('[markdown link](TargetPage)', s:links[0].content)
call assert_equal([3, 41], s:links[0].pos_start)

" Wrapped wiki link: [[Some\nPage]]
call assert_equal('wiki', s:links[1].type)
call assert_equal('Some Page', s:links[1].url_raw)
call assert_equal('[[Some Page]]', s:links[1].content)
call assert_equal([6, 17], s:links[1].pos_start)

" Wrapped orgmode link: [[OrgTarget][org\ndescription]]
call assert_equal('org', s:links[2].type)
call assert_equal('OrgTarget', s:links[2].url_raw)
call assert_equal('[[OrgTarget][org description]]', s:links[2].content)
call assert_equal([9, 17], s:links[2].pos_start)

" Wrapped markdown image: ![figure\ncaption](Image.png)
call assert_equal('md_fig', s:links[3].type)
call assert_equal('Image.png', s:links[3].url_raw)
call assert_equal('![figure caption](Image.png)', s:links[3].content)
call assert_equal([12, 10], s:links[3].pos_start)

" The single-line link is unaffected.
call assert_equal('md', s:links[4].type)
call assert_equal('OtherPage', s:links[4].url_raw)

call wiki#test#finished()
