source init.vim

let g:wiki_list_todos = ['TODO', 'INPROGRESS', 'DONE']

silent edit ex1-basic/lists.wiki

"
" Checkbox lists
"
call wiki#list#toggle(7)
call wiki#list#toggle(10)
let [s:root, s:current] = wiki#list#get(3)
if len(s:current.children) != 3
  call wiki#test#error(expand('<sfile>'), 'There should be two entries at same level.')
  call wiki#test#append(len(s:current.children))
  call wiki#test#append(wiki#list#print(s:current))
endif

if !s:current.checked
  call wiki#test#error(expand('<sfile>'), 'This entry should have been checked!')
  call wiki#test#append(wiki#list#print(s:current))
endif
if !s:root.children[1].children[0].checked
  call wiki#test#error(expand('<sfile>'), 'This entry should have been checked!')
  call wiki#test#append(wiki#list#print(s:root.children[1].children[0]))
endif

"
" Todo lists
"
call wiki#list#toggle(17)
let [s:root, s:current] = wiki#list#get(17)
if s:current.states[s:current.state] !=# 'DONE'
  call wiki#test#error(expand('<sfile>'),
        \ 'This entry should have been toggled to DONE!')
  call wiki#test#append(wiki#list#print(s:current))
endif

call wiki#test#quit()
