source ../init.vim

function! TemplateB(context) abort " {{{1
  call append(0, [
        \ 'Hello from TemplateB function!',
        \ string(a:context),
        \])
endfunction

" }}}1
let g:wiki_root = g:testroot . '/wiki-basic'
let g:wiki_templates = [
      \ {
      \   'match_re': '^Template A',
      \   'source_filename': g:testroot . '/test-templates/template-a.md'
      \ },
      \ {
      \   'match_re': '^Template B',
      \   'source_func': function('TemplateB')
      \ },
      \]

runtime plugin/wiki.vim

call wiki#page#open('Template B')
" call assert_true(b:wiki.in_journal)

" bwipeout!
" let g:wiki_journal.date_format.daily = '%d.%m.%Y'
" let s:date = strftime(g:wiki_journal.date_format[g:wiki_journal.frequency])
" silent call wiki#journal#make_note()
" call assert_equal(s:date, expand('%:t:r'))

" let s:step = index(sort(['01.02.2019', s:date]), s:date)
"       \ ? -1 : 1
" silent call wiki#journal#go(s:step)
" call assert_equal('01.02.2019', expand('%:t:r'))

" silent bwipeout!
" let g:wiki_journal.frequency = 'weekly'
" let s:date = strftime(g:wiki_journal.date_format[g:wiki_journal.frequency])
" silent call wiki#journal#make_note()
" call assert_equal(expand('%:t:r'), s:date)
" silent call wiki#journal#go(-1)
" call assert_equal(expand('%:t:r'), '2019_w02')

" silent bwipeout!
" let g:wiki_journal.frequency = 'monthly'
" let s:date = strftime(g:wiki_journal.date_format[g:wiki_journal.frequency])
" silent call wiki#journal#make_note()
" call assert_equal(expand('%:t:r'), s:date)
" silent call wiki#journal#go(-1)
" call assert_equal(expand('%:t:r'), '2019_m02')

" call wiki#test#finished()
