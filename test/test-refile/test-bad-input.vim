source ../init.vim
runtime plugin/wiki.vim

let g:wiki_log_verbose = 0

let s:n = 0
function! s:assert_error(msg) abort
  let s:n += 1
  let l:log = wiki#log#get()
  call assert_equal(s:n, len(l:log), 'Unexpected number of log entries')
  if len(l:log) < s:n | return | endif
  call assert_equal('error', l:log[s:n - 1].type)
  call assert_equal(a:msg, l:log[s:n - 1].msg[0])
endfunction

silent edit wiki-tmp/index.wiki

" Refile something not within a section
normal 2G
silent call wiki#page#refile()
call s:assert_error('No source section recognized!')

normal! 13G

" Refile to a nonexisting page
silent call wiki#page#refile(#{target_page: 'targetDoesNotExist'})
call s:assert_error('Target page was not found!')

" Refile to a nonexisting anchor
silent call wiki#page#refile(#{target_anchor: '#No#Such#Section'})
call s:assert_error('Target anchor not recognized!')

" Refile a section into itself
silent call wiki#page#refile(#{target_anchor: '#Section 1'})
call s:assert_error('Cannot refile a section into itself!')
silent call wiki#page#refile(#{target_anchor: '#Section 1#Foo bar Baz'})
call s:assert_error('Cannot refile a section into itself!')
silent call wiki#page#refile(#{target_lnum: 13})
call s:assert_error('Cannot refile a section into itself!')

" Refile beyond the maximum header level
silent edit wiki-tmp/deep.wiki
normal! 3G
silent call wiki#page#refile(#{
      \ target_anchor: '#Target#Deep target',
      \ target_relation: 'inside'
      \})
call s:assert_error('Refiling would exceed the maximum header level!')

" None of the above should have modified any file
for s:file in ['index', 'deep']
  call assert_equal(
        \ readfile('wiki/' . s:file . '.wiki'),
        \ readfile('wiki-tmp/' . s:file . '.wiki'))
endfor

call wiki#test#finished()
