source ../init.vim
runtime plugin/wiki.vim

let g:wiki_cache_persistent = 0

silent edit wiki-tmp/index.wiki

silent let s:tags = wiki#tags#get_all()
call assert_equal(8, len(s:tags))
call assert_equal(1, len(s:tags.tag1))
call assert_equal(2, len(s:tags.marked))

call assert_equal(
          \ ':tag_six: :tag3: :tag4: :tag5: :tag6:',
          \ readfile('wiki-tmp/tagged.wiki')[1])
" Basic renaming
silent call wiki#tags#rename('tag4', 'tag_four', 1)
" Rename to an existing tag
silent call wiki#tags#rename('tag5', 'tag_four', 1)
" Rename to an existing tag, keeping original ordering
silent call wiki#tags#rename('tag6', 'tag_six', 1)
call assert_equal(
          \ ':tag_six: :tag3: :tag_four:',
          \ readfile('wiki-tmp/tagged.wiki')[1])

call wiki#test#finished()
