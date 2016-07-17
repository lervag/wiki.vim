" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#parse(string, ...) " {{{1
  "
  " The following is a description of a typical url object
  "
  "   url = {
  "     'string'   : The original url string (unaltered)
  "     'url'      : The full url (after parsing)
  "     'scheme'   : The scheme of the url
  "     'stripped' : The url without the preceding scheme
  "     'origin'   : Where the url originates
  "     'open'     : Method to open the url
  "   }
  "
  let l:options = a:0 > 0 ? a:1 : {}

  let l:url = {}
  let l:url.string = a:string
  let l:url.url = a:string
  let l:url.origin = get(l:options, 'origin', expand('%:p'))

  " Decompose string into its scheme and stripped url
  let l:parts = matchlist(a:string, '\v((\w+):%(//)?)?(.*)')
  let l:url.stripped = l:parts[3]
  if empty(l:parts[2])
    let l:url.scheme = 'wiki'
    let l:url.url = l:url.scheme . ':' . a:string
  else
    let l:url.scheme = l:parts[2]
  endif

  " Extend through specific parsers
  return extend(l:url, get({
        \   'wiki'  : s:url_wiki_parse(l:url),
        \   'diary' : s:url_wiki_parse(l:url),
        \   'file'  : s:url_file_parse(l:url),
        \   'doi'   : s:url_doi_parse(l:url),
        \ }, l:url.scheme,
        \ { 'open' : function('s:url_external_open') }))
endfunction

" }}}1

function! s:url_wiki_parse(url) " {{{1
  let l:url = {}
  let l:url.open = function('s:url_wiki_open')
  let l:url.open_anchor = function('s:url_wiki_open_anchor')

  " Extract anchor
  let l:anchors = split(a:url.stripped, '#', 1)
  let l:url.anchor = len(l:anchors) > 1 && l:anchors[-1] != ''
        \ ? join(l:anchors[1:], '#') : ''

  " Extract filename
  let l:fname = (!empty(l:anchors[0])
        \ ? l:anchors[0]
        \ : fnamemodify(a:url.origin, ':p:t:r')) . '.wiki'

  " Extract path
  if a:url.scheme ==# 'diary'
    let l:url.scheme = 'wiki'
    let l:url.path = g:wiki.diary . l:fname
  else
    let l:url.path = l:fname[0] ==# '/'
          \ ? g:wiki.root . strpart(l:fname, 1)
          \ : fnamemodify(a:url.origin, ':p:h') . '/' . l:fname
  endif

  return l:url
endfunction

" }}}1
function! s:url_wiki_open(...) dict " {{{1
  let l:cmd = a:0 > 0 ? a:1 : 'edit'

  " Check if dir exists
  let l:dir = fnamemodify(self.path, ':p:h')
  if !isdirectory(l:dir)
    echom 'wiki Error: Unable to edit in non-existent directory:' l:dir
    return
  endif

  " Open wiki file
  if resolve(self.path) !=# resolve(expand('%:p'))
    if resolve(self.origin) ==# resolve(expand('%:p'))
      let l:prev_link = [expand('%:p'), getpos('.')]
    elseif &filetype ==# 'wiki'
      let l:prev_link = [self.origin, []]
    endif

    execute l:cmd fnameescape(self.path)

    if exists('l:prev_link')
      let b:wiki.prev_link = l:prev_link
    endif
  endif

  " Go to anchor
  if !empty(self.anchor)
    call self.open_anchor()
  endif

  " Focus
  normal! zMzvzz
endfunction

"}}}1
function! s:url_wiki_open_anchor() dict " {{{1
  let l:old_pos = getpos('.')
  call cursor(1, 1)

  for l:part in split(self.anchor, '#', 0)
    let l:header = '^#\{1,6}\s*' . l:part . '\s*$'
    let l:bold = wiki#rx#surrounded(l:part, '*')

    if !(search(l:header, 'Wc') || search(l:bold, 'Wc'))
      call setpos('.', l:old_pos)
      break
    endif
    let l:old_pos = getpos('.')
  endfor
endfunction

" }}}1

function! s:url_file_parse(url) " {{{1
  if a:url.stripped[0] ==# '/'
    let l:path = a:url.stripped
  elseif a:url.stripped =~# '\~\w*\/'
    let l:path = simplify(fnamemodify(a:url.stripped, ':p'))
  else
    let l:path = simplify(
          \ fnamemodify(a:url.origin, ':p:h') . '/' . a:url.stripped)
  endif

  return {
        \ 'open' : function('s:url_file_open'),
        \ 'path' : l:path,
        \}
endfunction

" }}}1
function! s:url_file_open(...) dict " {{{1
  if isdirectory(self.path)
    execute 'Unite file:' . self.path
    return
  endif

  if !filereadable(self.path) | return | endif

  if self.path =~# 'pdf$'
    silent execute '!zathura' self.path '&'
    return
  endif

  execute 'edit' self.path
endfunction

"}}}1

function! s:url_doi_parse(url) " {{{1
  return {
        \ 'scheme' : 'http',
        \ 'stripped' : 'dx.doi.org/' . a:url.stripped,
        \ 'url' : 'http://dx.doi.org/' . a:url.stripped,
        \ 'open' : function('s:url_external_open'),
        \}
endfunction

" }}}1

function! s:url_external_open(...) dict " {{{1
  call system('xdg-open ' . shellescape(self.url) . '&')
endfunction

"}}}1


" vim: fdm=marker sw=2
