source init.vim

silent edit example/lists.wiki
normal! 4G
call wiki#list#toggle()
let s:entries = wiki#list#get_current()
if !s:entries[0].checked
  call wiki#test#error(expand('<sfile>'), 'The list entry should have been checked.')
endif

call wiki#test#quit()
