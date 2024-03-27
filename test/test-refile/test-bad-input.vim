source ../init.vim
runtime plugin/wiki.vim

let g:wiki_log_verbose = 0

silent edit wiki-tmp/index.wiki

" Refile something not within a section should return with error message
normal 2G
silent call wiki#page#refile()
let s:log = wiki#log#get()
call assert_equal(1, len(s:log))
call assert_equal('error', s:log[0].type)
call assert_equal('No source section recognized!', s:log[0].msg[0])

" Refile to nonexisting target should return with error message
normal! 13G
silent call wiki#page#refile(#{target_page: 'targetDoesNotExist'})
let s:log = wiki#log#get()
call assert_equal(2, len(s:log))
call assert_equal('error', s:log[1].type)
call assert_equal('Target page was not found!', s:log[1].msg[0])

call wiki#test#finished()
