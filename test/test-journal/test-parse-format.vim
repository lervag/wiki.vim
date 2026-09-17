source ../init.vim
runtime plugin/wiki.vim

" Regular parsing of the supported fields
call assert_equal(
      \ { 'year': '2020', 'month': '03', 'day': '17' },
      \ wiki#date#parse_format('2020-03-17', '%Y-%m-%d'))
call assert_equal(
      \ { 'year': '2020', 'month': '03', 'day': '17' },
      \ wiki#date#parse_format('2020/03/17', '%Y/%m/%d'))
call assert_equal(
      \ { 'year': '2019', 'week_iso': '02' },
      \ wiki#date#parse_format('2019_w02', '%Y_w%V'))
call assert_equal(
      \ { 'year': '2020', 'month': '03' },
      \ wiki#date#parse_format('2020_m03', '%Y_m%m'))

" Two digit years are expanded
call assert_equal(
      \ { 'year': '2020', 'month': '03', 'day': '17' },
      \ wiki#date#parse_format('20-03-17', '%y-%m-%d'))

" Trailing text is ignored
call assert_equal(
      \ { 'year': '2020', 'month': '03', 'day': '17' },
      \ wiki#date#parse_format('2020-03-17 and more', '%Y-%m-%d'))

" The text between the fields is matched by length and not by content. This
" matters because a date string is not always parsed with the format it was
" created with, see e.g. wiki#journal#date_to_node.
call assert_equal(
      \ { 'year': '2019', 'week_iso': '02' },
      \ wiki#date#parse_format('2019_w02', '%Y-w%V'))
call assert_equal(
      \ { 'year': '2019', 'week_iso': '02' },
      \ wiki#date#parse_format('2019-w02', '%Y_w%V'))

" Strings that do not match the format are not parsed
call assert_equal({}, wiki#date#parse_format('archive/2018-05-05', '%Y-%m-%d'))
call assert_equal({}, wiki#date#parse_format('2020-03', '%Y-%m-%d'))
call assert_equal({}, wiki#date#parse_format('', '%Y-%m-%d'))
call assert_equal({}, wiki#date#parse_format('whatever', 'no fields'))

call wiki#test#finished()
