" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#vimdoc#handler(url) abort " {{{1
  let l:handler = deepcopy(s:handler)
  let l:handler.page = self.stripped
  return l:handler
endfunction

" }}}1


let s:handler = {}
function! s:handler.follow(...) abort dict " {{{1
  try
    execute 'help' self.page
    execute winnr('#') 'hide'
  catch
    call wiki#log#warn('can''t find vimdoc page "' . self.page . '"')
  endtry
endfunction

" }}}1
