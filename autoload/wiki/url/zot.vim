" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#zot#handler(url) abort " {{{1
  let l:handler = deepcopy(s:handler)
  let l:handler.key = a:url.stripped
  return l:handler
endfunction

" }}}1


let s:handler = {}
function! s:handler.follow(...) abort dict " {{{1
  let l:files = wiki#zotero#search(self.key)

  if len(l:files) > 0
    let l:choice = wiki#ui#select(
          \ ['Follow in Zotero: ' . self.key]
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
      call wiki#jobs#run(g:wiki_viewer['_'] . ' ' . shellescape(l:file) . '&')
      return
    endif
  endif

  " Fall back to zotero://select/items/bbt:citekey
  call wiki#jobs#run(printf('%s zotero://select/items/bbt:%s &',
        \ g:wiki_viewer['_'], self.key))
endfunction

" }}}¡


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
