" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#ref_definition#matcher() abort " {{{1
  return extend(wiki#link#_template#matcher(), deepcopy(s:matcher))
endfunction

" }}}1


let s:matcher = {
      \ 'type': 'ref_definition',
      \ 'rx': wiki#rx#link_ref_definition,
      \ 'rx_url': '\[' . wiki#rx#reflabel . '\]:\s\+\zs' . wiki#rx#url,
      \ 'rx_text': '^\s*\[\zs' . wiki#rx#reflabel . '\ze\]',
      \}

function! s:matcher.transform_template(url, id) abort " {{{1
  let l:id = empty(a:id) ? wiki#ui#input(#{info: 'Input id: '}) : a:id
  return '[' . l:id . ']: ' . a:url
endfunction

" }}}1
