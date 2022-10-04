" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#journal#handler(url) abort " {{{1
  let [l:path, l:frq] = wiki#journal#date_to_node(a:url.stripped)

  if empty(l:path)
    let l:handler = deepcopy(s:dummy_handler)
    let l:handler.date = a:url.stripped
    return l:handler
  endif

  let a:url.stripped = printf('/%s/%s', g:wiki_journal.name, l:path)
  return wiki#url#wiki#handler(a:url)
endfunction

" }}}1


let s:dummy_handler = {
      \ 'date': 'N/A'
      \}
function! s:dummy_handler.follow(...) abort dict
  call wiki#log#warn('Could not parse the journal date: ' . self.date)
endfunction
