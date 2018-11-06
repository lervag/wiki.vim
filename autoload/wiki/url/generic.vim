" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#url#generic#parse(url) abort " {{{1
  let l:parser = {}
  function! l:parser.open(...) abort dict
    call system(g:wiki_generic_viewer . ' ' . shellescape(self.url) . '&')
  endfunction

  return deepcopy(l:parser)
endfunction

" }}}1
