source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'

" Use temporary journal roots with entries for the relevant frequencies
let s:root_weekly = tempname()
call mkdir(s:root_weekly, 'p')
for s:name in ['2020_w03', '2020_w04', '2020_w30']
  call writefile([], printf('%s/%s.wiki', s:root_weekly, s:name))
endfor

let s:root_monthly = tempname()
call mkdir(s:root_monthly, 'p')
for s:name in ['2020_m01', '2020_m07', '2021_m03']
  call writefile([], printf('%s/%s.wiki', s:root_monthly, s:name))
endfor

function! s:index() abort
  enew!
  setlocal buftype=nofile
  call wiki#journal#make_index()
  return getline(1, '$')
endfunction


" The index must be grouped by the month of each entry, also when the journal
" frequency is not daily
let g:wiki_journal = { 'root': s:root_weekly, 'frequency': 'weekly' }
runtime plugin/wiki.vim

call assert_equal([
      \ '',
      \ '# 2020',
      \ '',
      \ '## January',
      \ '',
      \ '[[journal:2020-w03|2020-w03]]',
      \ '[[journal:2020-w04|2020-w04]]',
      \ '',
      \ '## July',
      \ '',
      \ '[[journal:2020-w30|2020-w30]]',
      \ '',
      \], s:index())


unlet g:wiki_loaded
let g:wiki_journal = { 'root': s:root_monthly, 'frequency': 'monthly' }
runtime plugin/wiki.vim

call assert_equal([
      \ '',
      \ '# 2020',
      \ '',
      \ '## January',
      \ '',
      \ '[[journal:2020-01|2020-01]]',
      \ '',
      \ '## July',
      \ '',
      \ '[[journal:2020-07|2020-07]]',
      \ '',
      \ '# 2021',
      \ '',
      \ '## March',
      \ '',
      \ '[[journal:2021-03|2021-03]]',
      \ '',
      \], s:index())


call delete(s:root_weekly, 'rf')
call delete(s:root_monthly, 'rf')
call wiki#test#finished()
