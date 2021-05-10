" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#man#handler(url) abort " {{{1
  let l:path = 'man://' . matchstr(a:url.url, 'man:\(\/\/\)\?\zs[^-]*')
  let l:section = matchstr(a:url.url, '-\zs\d$')
  if !empty(l:section)
    let l:path .= '(' . l:section . ')'
  endif

  let l:handler = deepcopy(s:handler)
  let l:handler.path = l:path
  return l:handler
endfunction

" }}}1


let s:handler = {}
function! s:handler.follow(...) abort dict " {{{1
  execute 'edit' fnameescape(self.path)
endfunction

" }}}1
