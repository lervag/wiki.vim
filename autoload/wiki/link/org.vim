" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#org#matcher() abort " {{{1
  return extend(wiki#link#_template#matcher(), deepcopy(s:matcher))
endfunction

" }}}1
function! wiki#link#org#template(url, text) abort " {{{1
  return empty(a:text) || a:text ==# a:url || a:text ==# a:url[1:]
        \ ? '[[' . a:url . ']]'
        \ : '[[' . a:url . '][' . a:text . ']]'
endfunction

" }}}1


let s:matcher = {
      \ 'type' : 'org',
      \ 'rx' : g:wiki#rx#link_org,
      \ 'rx_url' : '\[\[\zs\/\?[^\\\]]\{-}\ze\]\%(\[[^\\\]]\{-}\]\)\?\]',
      \ 'rx_text' : '\[\[\/\?[^\\\]]\{-}\]\[\zs[^\\\]]\{-}\ze\]\]',
      \}
