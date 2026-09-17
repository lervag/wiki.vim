source ../init.vim

let g:wiki_root = g:testroot . '/wiki-basic'

" Use a temporary journal root, so that entries may be added and removed
let s:root = tempname()
call mkdir(s:root . '/2019/01', 'p')
for s:day in ['01', '02', '03']
  call writefile([], printf('%s/2019/01/%s.wiki', s:root, s:day))
endfor

let g:wiki_journal = {
      \ 'root': s:root,
      \ 'date_format': { 'daily': '%Y/%m/%d' },
      \}
runtime plugin/wiki.vim

function! s:nodes() abort
  return sort(wiki#journal#get_all_nodes('daily'))
endfunction

" The cached node list is returned by reference, so we may poison it in order
" to observe whether a lookup uses the cache or rescans the journal tree.
function! s:poison() abort
  let l:data = wiki#cache#open('journal-nodes').data
  for l:key in keys(l:data)
    call add(l:data[l:key].nodes, 'poison')
  endfor
endfunction

function! s:is_cached() abort
  return index(wiki#journal#get_all_nodes('daily'), 'poison') >= 0
endfunction

" getftime has a resolution of one second, and the cache deliberately
" distrusts stamps from the current second. We must therefore cross a second
" boundary before the cache may be observed to settle.
function! s:next_second() abort
  let l:time = localtime()
  while localtime() == l:time
    sleep 50m
  endwhile
endfunction

call assert_equal(['2019/01/01', '2019/01/02', '2019/01/03'], s:nodes())


" The node list is cached when the journal tree does not change, and changing
" the contents of an entry does not invalidate it. Both are checked within the
" same settled window, so that we only have to wait once.
call s:next_second()
call s:nodes()
call s:poison()
call assert_true(s:is_cached(), 'expected cached node list to be reused')

call writefile(['Hello world!'], s:root . '/2019/01/01.wiki')
call assert_true(s:is_cached(),
      \ 'expected cached node list to survive a content change')


" A new entry invalidates the cache
call writefile([], s:root . '/2019/01/04.wiki')
call assert_equal(
      \ ['2019/01/01', '2019/01/02', '2019/01/03', '2019/01/04'],
      \ s:nodes())


" A removed entry invalidates the cache
call delete(s:root . '/2019/01/04.wiki')
call assert_equal(['2019/01/01', '2019/01/02', '2019/01/03'], s:nodes())


" An entry in a new subdirectory invalidates the cache
call mkdir(s:root . '/2020/03', 'p')
call writefile([], s:root . '/2020/03/01.wiki')
call assert_equal(
      \ ['2019/01/01', '2019/01/02', '2019/01/03', '2020/03/01'],
      \ s:nodes())


call delete(s:root, 'rf')
call wiki#test#finished()
