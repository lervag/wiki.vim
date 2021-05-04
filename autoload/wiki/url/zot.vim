" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#zot#parse(url) abort " {{{1
  let l:parser = {}

  function! l:parser.follow(...) abort dict
    let l:files = wiki#zotero#search(self.stripped)

    if len(l:files) > 0
      let l:choice = wiki#ui#choose(
            \ ['Follow in Zotero: ' . self.stripped]
            \   + map(copy(l:files), 's:menu_open_pdf(v:val)'),
            \ {
            \   'prompt': 'Please select desired action:',
            \   'return': 'index',
            \ })
      if l:choice < 0
        return wiki#log#warn('Aborted')
      endif

      if l:choice > 0
        let l:file = l:files[l:choice-1]
        call system(g:wiki_viewer['_'] . ' ' . shellescape(l:file) . '&')
        return
      endif
    endif

    " Fall back to zotero://select/items/bbt:citekey
    call system(printf('%s zotero://select/items/bbt:%s &',
          \ g:wiki_viewer['_'], self.stripped))
  endfunction

  return l:parser
endfunction

" }}}1

function! s:menu_open_pdf(val) abort " {{{1
  let l:filename = fnamemodify(a:val, ':t')

  let l:strlen = strchars(l:filename)
  let l:width = winwidth(0) - 14
  if l:strlen > l:width
    let l:pre = strcharpart(l:filename, 0, l:width/2 - 3)
    let l:post = strcharpart(l:filename, l:strlen - l:width/2 + 3)
    let l:filename = l:pre . ' ... ' . l:post
  endif

  return 'Open PDF: ' . l:filename
endfunction

" }}}1
