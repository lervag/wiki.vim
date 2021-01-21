source ../init.vim

silent edit ../wiki-basic/lists.wiki

" Numbered lists general
let [s:root, s:current] = wiki#list#parser#get_at(22)
call wiki#test#assert_equal(
      \ '1. Ordered lists are also cool',
      \ s:current.text[0])

" Numbered todo lists
call wiki#list#toggle(23)
let [s:root, s:current] = wiki#list#parser#get_at(23)
call wiki#test#assert_equal('DONE', s:current.states[s:current.state])

if $QUIT | quitall! | endif
