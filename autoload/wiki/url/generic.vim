" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#generic#parse(url) abort " {{{1
  let l:parser = {}
  function! l:parser.follow(...) abort dict
    call system(g:wiki_viewer['_'] . ' ' . shellescape(self.url) . '&')
  endfunction

  return deepcopy(l:parser)
endfunction

" }}}1
