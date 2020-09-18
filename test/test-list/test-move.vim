source ../init.vim

let g:wiki_list_todos = ['TODO', 'INPROGRESS', 'DONE']

silent edit wiki/move_in.wiki

call wiki#list#move(0, 5)
call wiki#list#move(0, 7)
call wiki#list#move(0, 7)
call wiki#list#move(1, 10)
call wiki#list#move(1, 3)
call wiki#list#move(1, 6)
call wiki#list#move(1, 20)

let s:reference = readfile('wiki/move_out.wiki')
let s:result = getline(1, '$')

call wiki#test#assert_equal(s:reference, s:result)


if $QUIT | quitall! | endif
