source ../init.vim
runtime plugin/wiki.vim

silent edit wiki-tmp/boundaries.wiki
normal! 7G
silent call wiki#page#refile(#{
      \ target_anchor: '#Intro',
      \ target_relation: 'inside'
      \})

let s:page = readfile('wiki-tmp/boundaries.wiki')
let s:other = readfile('wiki-tmp/boundaries-links.wiki')

" Links to the moved section and to its subsections are updated. Note that the
" anchor ends in a non-word character, and that both links on the line must be
" updated exactly once.
call assert_equal(
      \ '[[#Intro#A.B (v2)]] and [[#Intro#A.B (v2)#Sub]]', s:page[2])
call assert_equal(
      \ '[[boundaries#Intro#A.B (v2)]] and [[boundaries#Intro#A.B (v2)#Sub]]',
      \ s:other[2])

" The anchor is not a regular expression, so "#A.B …" must not match "#AxB …"
call assert_equal('[[#AxB (v2)]]', s:page[3])
call assert_equal('[[boundaries#AxB (v2)]]', s:other[3])

" An anchor ends at a subanchor or at the end of the link, not at a word
" boundary, so "#A.B (v2)" must not match within "#A.B (v2) extra"
call assert_equal('[[#A.B (v2) extra]]', s:page[4])
call assert_equal('[[boundaries#A.B (v2) extra]]', s:other[4])

call wiki#test#finished()
