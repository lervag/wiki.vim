" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#url#zot#parse(url) abort " {{{1
  let l:parser = {}

  function! l:parser.open(...) abort dict
    let l:files = wiki#zotero#search(self.stripped)

    if len(l:files) >= 1
      if len(l:files) > 1
        let l:choice = wiki#menu#choose(
              \ map(copy(l:files), 'fnamemodify(v:val, '':t'')'),
              \ {'header': 'multiple citekeys found, please select one:'})
        if l:choice < 0
          echo 'wiki: aborted'
          return
        endif
        let l:file = l:files[l:choice]
      else
        let l:file = l:files[0]
      endif

      call system(g:wiki_viewer['_'] . ' ' . shellescape(l:file) . '&')
    else
      echo 'wiki: could not find Zotero citekey "' . self.stripped . '"'
    endif
  endfunction

  return l:parser
endfunction

" }}}1
