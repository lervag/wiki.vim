source ../init.vim
runtime plugin/wiki.vim

call assert_equal(1080169200, wiki#date#strptime#isodate_implicit('2004-03-25'))
call assert_equal(1665784800, wiki#date#strptime#isodate_implicit('2022-10-15'))
call assert_equal(1798671600, wiki#date#strptime#isodate_implicit('2026-12-31'))

call wiki#test#finished()
