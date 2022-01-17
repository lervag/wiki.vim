" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#generic#handler(url) abort " {{{1
  let l:handler = deepcopy(s:handler)
  let l:handler.url = a:url.url

  return l:handler
endfunction

" }}}1


let s:handler = {}
function! s:handler.follow(...) abort dict " {{{1
  try
    call netrw#BrowseX(self.url, 0)
    return
  catch
  endtry

  call wiki#jobs#run(
        \ g:wiki_viewer['_'] . ' ' . shellescape(self.url) . '&')
endfunction

" }}}1
