" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#zotero#search(string) " {{{1
  if executable('fd') || executable('fdfind')
    let l:finder = (executable('fd') ? 'fd ' : 'fdfind ')
          \ . '-t f -e pdf '
          \ . (empty(a:string)
          \    ? '. '
          \    : '"' . a:string . '" ')
          \ . escape(g:wiki_zotero_root, ' ')
  else
    let l:finder = 'find '
          \ . escape(g:wiki_zotero_root, ' ')
          \ . ' -name "' . a:string . '*.pdf" -type f'
  endif

  let l:files = systemlist(l:finder)

  if v:shell_error != 0
    echom 'wiki:' l:finder
    for l:line in l:files
      echom l:line
    endfor
    throw 'wiki: error in wiki#zotero#search!'
  endif

  return l:files
endfunction

" }}}1
