" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#complete#omnicomplete(findstart, base) " {{{1
  if a:findstart
    let l:line = getline('.')[:col('.')-2]

    return match(l:line,
          \     '\[\[\zs[^\\[\]]*$'
          \ . '\|\[.*\](\zs[^)]*$')
  else
    if a:base =~# '#'
      let l:segments = split(a:base, '#', 1)
      let l:base = join(l:segments[1:], '#')
      let l:link_info = vimwiki#link#resolve(
            \ (l:segments[0] == '' ? expand('%:t:r') : l:segments[0]) . '#')

      return map(
            \   filter(
            \     vimwiki#base#get_anchors(l:link_info.filename, 'markdown'),
            \     'v:val =~# ''^'' . vimwiki#u#escape(l:base)'),
            \   'l:segments[0] . ''#'' . v:val')
    else
      return filter(vimwiki#base#get_wikilinks(0, 1),
            \ 'v:val =~# ''^'' . vimwiki#u#escape(a:base)')
    endif
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
