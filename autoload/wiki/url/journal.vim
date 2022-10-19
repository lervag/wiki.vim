" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#journal#handler(url) abort " {{{1
  let l:matches = matchlist(a:url.stripped, '\v([^#]*)(#.*)')
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

  let a:url.stripped = printf('/%s/%s%s',
        \ g:wiki_journal.name, l:path, l:anchor)
  return wiki#url#wiki#handler(a:url)
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
