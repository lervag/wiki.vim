" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#handlers#adoc(resolved, edit_cmd) abort " {{{1
  let l:do_edit = resolve(a:resolved.path) !=# resolve(expand('%:p'))

  call wiki#url#utils#go_to_file(
        \ a:resolved.path, a:edit_cmd, a:resolved.stripped, l:do_edit)
  call wiki#url#utils#go_to_anchor_adoc(a:resolved.anchor, l:do_edit)
  call wiki#url#utils#focus(l:do_edit)

  if exists('#User#WikiLinkFollowed')
    doautocmd <nomodeline> User WikiLinkFollowed
  endif
endfunction

" }}}1
function! wiki#url#handlers#doi(resolved, ...) abort " {{{1
  let a:resolved.url = 'http://dx.doi.org/' . a:resolved.stripped
  let a:resolved.scheme = 'http'
  let a:resolved.stripped = strpart(a:resolved.url, 5)

  return wiki#url#handlers#generic(a:resolved)
endfunction

" }}}1
function! wiki#url#handlers#file(resolved, ...) abort " {{{1
  let l:cmd = get(g:wiki_viewer, a:resolved.ext, g:wiki_viewer._)
  if l:cmd ==# ':edit'
    silent execute 'edit' fnameescape(a:resolved.path)
  else
    call wiki#jobs#run(l:cmd . ' ' . shellescape(a:resolved.path) . '&')
  endif
endfunction

" }}}1
function! wiki#url#handlers#generic(resolved, ...) abort " {{{1
  try
    call netrw#BrowseX(a:resolved.url, 0)
    return
  catch
  endtry

  call wiki#jobs#run(
        \ g:wiki_viewer['_'] . ' ' . shellescape(a:resolved.url) . '&')
endfunction

" }}}1
function! wiki#url#handlers#man(resolved, ...) abort " {{{1
  execute 'edit' fnameescape(a:resolved.path)
endfunction

" }}}1
function! wiki#url#handlers#refbad(resolved, ...) abort " {{{1
  normal! m'
  call cursor(a:resolved.lnum, 1)
endfunction

" }}}1
function! wiki#url#handlers#vimdoc(resolved, ...) abort " {{{1
  try
    execute 'help' a:resolved.stripped
    execute winnr('#') 'hide'
  catch
    call wiki#log#warn('can''t find vimdoc page "' . a:resolved.stripped . '"')
  endtry
endfunction

" }}}1
function! wiki#url#handlers#wiki(resolved, edit_cmd) abort " {{{1
  let l:do_edit = resolve(a:resolved.path) !=# resolve(expand('%:p'))

  call wiki#url#utils#go_to_file(
        \ a:resolved.path, a:edit_cmd, a:resolved.stripped, l:do_edit)
  call wiki#url#utils#go_to_anchor_wiki(a:resolved.anchor, l:do_edit)
  call wiki#url#utils#focus(l:do_edit)

  if exists('#User#WikiLinkFollowed')
    doautocmd <nomodeline> User WikiLinkFollowed
  endif
endfunction

" }}}1
function! wiki#url#handlers#zot(resolved, ...) abort " {{{1
  let l:files = wiki#zotero#search(a:resolved.stripped)

  if len(l:files) > 0
    let l:choice = wiki#ui#select(
          \ ['Follow in Zotero: ' . a:resolved.stripped]
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
      let l:viewer = get(g:wiki_viewer, 'pdf', g:wiki_viewer._)
      call wiki#jobs#start(l:viewer . ' ' . shellescape(l:file))
      return
    endif
  endif

  " Fall back to zotero://select/items/bbt:citekey
  call wiki#jobs#run(printf('%s zotero://select/items/bbt:%s &',
        \ g:wiki_viewer['_'], a:resolved.stripped))
endfunction

" }}}1
function! wiki#url#handlers#bdsk(resolved, ...) abort " {{{1
  let l:encoded_url = stridx(a:url.stripped, "%") < 0
        \ ? wiki#url#utils#url_encode(a:url.stripped)
        \ : a:url.stripped

  let a:resolved.url = 'x-bdsk://' . l:encoded_url
  let a:resolved.scheme = 'x-bdsk'

  return wiki#url#handlers#generic(a:resolved)
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
