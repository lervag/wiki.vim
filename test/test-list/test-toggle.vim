source ../init.vim

let g:wiki_list_todos = ['TODO', 'INPROGRESS', 'DONE']

silent edit ../wiki-basic/lists.wiki

" Checkbox lists
call wiki#list#toggle(7)
call wiki#list#toggle(10)
let [s:root, s:current] = wiki#list#parser#get_at(3)
call wiki#test#assert_equal(len(s:current.children), 3)
call wiki#test#assert(s:current.checked)
call wiki#test#assert(s:root.children[1].children[0].checked)

" Todo lists
call wiki#list#toggle(17)
let [s:root, s:current] = wiki#list#parser#get_at(17)
call wiki#test#assert_equal(s:current.states[s:current.state], 'DONE')

if $QUIT | quitall! | endif
