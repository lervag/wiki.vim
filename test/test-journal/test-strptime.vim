source ../init.vim
runtime plugin/wiki.vim

let s:start = strptime('%Y-%m-%d', '2021-01-01')
for s:x in map(range(730), { _, x -> s:start + x*86400 })
  let s:date = strftime('%Y-%m-%d', s:x)
  let s:expected = strptime('%Y-%m-%d', s:date)
  let s:observed = wiki#date#strptime#isodate_implicit(s:date)
  call assert_equal(s:expected, s:observed)
endfor

call wiki#test#finished()
