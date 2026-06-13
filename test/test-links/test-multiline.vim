source ../init.vim

runtime plugin/wiki.vim

" Links that are hard-wrapped across two lines should still be detected by the
" bulk extraction path (used by e.g. WikiGraphCheckLinks). See issue #147.
let s:lines = [
      \ '# Multi-line links',
      \ '',
      \ 'This is a paragraph with a hard-wrapped [markdown',
      \ 'link](TargetPage) that spans two lines.',
      \ '',
      \ 'And a wiki link [[Some',
      \ 'Page]] also wrapped here.',
      \ '',
      \ '```',
      \ 'A fenced code block with a [wrapped',
      \ 'link](ShouldBeIgnored) must not be detected.',
      \ '```',
      \ '',
      \ 'A trailing single-line [normal link](OtherPage) for good measure.',
      \]
let s:links = wiki#link#get_all_from_lines(s:lines, '/tmp/multiline.wiki')

" The wrapped markdown link, the wrapped wiki link and the trailing single-line
" link are found; the link inside the fenced code block is skipped.
call assert_equal(3, len(s:links))

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

" The single-line link is unaffected.
call assert_equal('md', s:links[2].type)
call assert_equal('OtherPage', s:links[2].url_raw)

call wiki#test#finished()
