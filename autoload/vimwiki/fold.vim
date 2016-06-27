" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#fold#level(lnum) " {{{1
  let l:line = getline(a:lnum)

  if l:line =~# '^#\{1,6} [^#]' && !s:is_code(a:lnum)
    return '>' . len(matchstr(l:line, '#*'))
  endif

  if l:line =~# '^```'
    return (s:is_code(a:lnum+1) ? 'a1' : 's1')
  endif

  return '='
endfunction

" }}}1
function! vimwiki#fold#text() " {{{1
  let l:line = getline(v:foldstart)
  let l:text = substitute(l:line, '^\s*', repeat(' ',indent(v:foldstart)), '')

  " Header fold text
  if l:line !~# g:vimwiki.rx.preStart
    let [l:text, spare_len] = s:shorten_text(l:text, 65)
    return l:text
  endif

  " Code block fold text
  return l:text
endfunction

" }}}1

function! s:is_code(lnum) " {{{1
  return match(map(synstack(a:lnum, 1),
          \        "synIDattr(v:val, 'name')"),
          \    '^\%(textSnip\|VimwikiPre\)') > -1
endfunction

" }}}1

" vim: fdm=marker sw=2
