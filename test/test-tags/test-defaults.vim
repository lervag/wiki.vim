source ../init.vim
runtime plugin/wiki.vim

let g:wiki_cache_persistent = 0
let g:wiki_log_verbose = 0

silent edit wiki-tmp/index.wiki

let s:tags = wiki#tags#get_all()
call assert_equal(8, len(s:tags))
call assert_equal(1, len(s:tags.tag1))
call assert_equal(2, len(s:tags.marked))

call assert_equal(
          \ ':tag_six: :tag3: :tag4: :tag5: :tag6:',
          \ readfile('wiki-tmp/tagged.wiki')[1])
" Basic renaming
call wiki#tags#rename('tag4', 'tag_four', 1)
" Rename to an existing tag
call wiki#tags#rename('tag5', 'tag_four', 1)
" Rename to an existing tag, keeping original ordering
call wiki#tags#rename('tag6', 'tag_six', 1)
call assert_equal(
          \ ':tag_six: :tag3: :tag_four:',
          \ readfile('wiki-tmp/tagged.wiki')[1])

call wiki#test#finished()
