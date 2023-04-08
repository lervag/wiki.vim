" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#journal#handler(url) abort " {{{1
  let l:matches = matchlist(a:url.stripped, '\v([^#]*)(#.*)?')
  let l:date = get(l:matches, 1, 'N/A')
  let l:anchor = get(l:matches, 2, 'N/A')

  let [l:path, l:frq] = wiki#journal#date_to_node(l:date)
  if empty(l:path)
    let l:handler = deepcopy(s:dummy_handler)
    let l:handler.url = a:url.stripped
    let l:handler.date = l:date
    let l:handler.anchor = l:anchor
    return l:handler
  endif

  let a:url.stripped = printf('%s%s', l:path, l:anchor)
  return wiki#url#wiki#handler(a:url, 'wiki#url#journal#resolver')
endfunction

" }}}1
function! wiki#url#journal#resolver(fname, origin) abort " {{{1
  if empty(g:wiki_journal.root)
    return wiki#url#wiki#resolver(
          \ printf('/%s/%s', g:wiki_journal.name, a:fname),
          \ a:origin)
  endif

  " This resolver is specifically designed to handle journals that are not
  " rooted to a parent wiki, i.e. where g:wiki_journal.root is not empty.
  let l:path = wiki#paths#s(g:wiki_journal.root . '/' . a:fname)

  " Collect extension candidates
  let l:extensions = wiki#u#uniq_unsorted(g:wiki_filetypes
        \ + (exists('b:wiki.extension') ? [b:wiki.extension] : []))
  if index(l:extensions, fnamemodify(l:path, ':e')) >= 0
    return l:path
  endif

  " Determine the proper extension (if necessary)
  for l:ext in l:extensions
    let l:newpath = l:path . '.' . l:ext
    if filereadable(l:newpath) | return l:newpath | endif
  endfor

  return l:path . '.' . l:extensions[0]
endfunction

" }}}1


let s:dummy_handler = {
      \ 'url': '',
      \ 'date': '',
      \ 'anchor': ''
      \}
function! s:dummy_handler.follow(...) abort dict
  call wiki#log#warn(
        \ 'Could not parse journal URL!',
        \ 'URL:    ' . self.url,
        \ 'Date:   ' . self.date,
        \ 'Anchor: ' . self.anchor,
        \)
endfunction
