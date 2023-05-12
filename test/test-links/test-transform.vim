source ../init.vim

let g:wiki_link_transforms = {
      \ 'wiki': 'WikiTransformer',
      \ 'md': 'MdTransformer',
      \}

function WikiTransformer(url, text, link) abort dict
  return wiki#link#templates#md(
        \ a:url . '.wiki',
        \ empty(a:text) ? a:url : a:text,
        \ a:link)
endfunction

function MdTransformer(url, text, link) abort dict
  let l:url = substitute(a:url, '\.wiki$', '', '')
  return wiki#link#templates#wiki(l:url, a:text, a:link)
endfunction

runtime plugin/wiki.vim

" Test transform normal on regular markdown links using wiki style links
silent edit ../wiki-basic/index.wiki
execute "normal \<plug>(wiki-link-next)"
silent execute "normal \<Plug>(wiki-link-transform)"
call assert_equal('[NewPage](NewPage.wiki)', getline('.'))
silent execute "normal \<Plug>(wiki-link-transform)"
call assert_equal('[[NewPage]]', getline('.'))

call wiki#test#finished()
