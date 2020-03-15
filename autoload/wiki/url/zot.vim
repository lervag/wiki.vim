" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#url#zot#parse(url) abort " {{{1
  let l:parser = {}
  function! l:parser.open(...) abort dict
    let l:files = systemlist(
          \ printf('fd -t f -e pdf "%s" ~/.local/zotero', self.stripped))

    if len(l:files) >= 1
      if len(l:files) > 1
        echo 'wiki: multiple Zotero citekeys found! Opening first one.'
        for l:f in l:files
          echo '-' substitute(l:f,
                \ '^.*\.local\/zotero\/storage\/[^\/]*\/', '', '')
        endfor
      endif

      call system(g:wiki_viewer['_'] . ' ' . shellescape(l:files[0]) . '&')
    else
      echo 'wiki: could not find Zotero citekey "' . self.stripped . '"'
    endif
  endfunction

  return l:parser
endfunction

" }}}1
