source init.vim

let g:wiki_root = fnamemodify(expand('<cfile>'), ':p:h') . '/ex3-journal'
let g:wiki_journal = {'name' : 'diary'}
runtime plugin/wiki.vim

try
  bwipeout!
  call wiki#journal#make_note()
  if !b:wiki.in_journal
    call wiki#test#error(expand('<sfile>'), 'Diary should have been opened.')
  endif
endtry

try
  bwipeout!
  let g:wiki_journal.date_format.daily = '%d.%m.%Y'
  let s:date = strftime(g:wiki_journal.date_format[g:wiki_journal.frequency])

  call wiki#journal#make_note()
  if expand('%:t:r') !=# s:date
    call wiki#test#error(expand('<sfile>'), 'Diary date format error:')
    call wiki#test#append([
          \ 'Got:      ' . expand('%:t:r'),
          \ 'Expected: ' . s:date
          \])
  endif

  call wiki#journal#go(-1)
  let s:date = '01.02.2019'
  if expand('%:t:r') !=# s:date
    call wiki#test#error(expand('<sfile>'), 'Diary date format error:')
    call wiki#test#append([
          \ 'Got:      ' . expand('%:t:r'),
          \ 'Expected: ' . s:date
          \])
  endif
endtry

try
  bwipeout!
  let g:wiki_journal.frequency = 'weekly'
  let s:date = strftime(g:wiki_journal.date_format[g:wiki_journal.frequency])
  call wiki#journal#make_note()

  if expand('%:t:r') !=# s:date
    call wiki#test#error(expand('<sfile>'), 'Diary date format error.')
    call wiki#test#append([
          \ 'Got:      ' . expand('%:t:r'),
          \ 'Expected: ' . s:date
          \])
  endif

  call wiki#journal#go(-1)
  let s:date = '2019_w02'
  if expand('%:t:r') !=# s:date
    call wiki#test#error(expand('<sfile>'), 'Diary date format error:')
    call wiki#test#append([
          \ 'Got:      ' . expand('%:t:r'),
          \ 'Expected: ' . s:date
          \])
  endif
endtry

try
  bwipeout!
  let g:wiki_journal.frequency = 'monthly'
  let s:date = strftime(g:wiki_journal.date_format[g:wiki_journal.frequency])
  call wiki#journal#make_note()

  if expand('%:t:r') !=# s:date
    call wiki#test#error(expand('<sfile>'), 'Diary date format error.')
    call wiki#test#append([
          \ 'Got:      ' . expand('%:t:r'),
          \ 'Expected: ' . s:date
          \])
  endif

  call wiki#journal#go(-1)
  let s:date = '2019_m02'
  if expand('%:t:r') !=# s:date
    call wiki#test#error(expand('<sfile>'), 'Diary date format error:')
    call wiki#test#append([
          \ 'Got:      ' . expand('%:t:r'),
          \ 'Expected: ' . s:date
          \])
  endif
endtry

call wiki#test#quit()
