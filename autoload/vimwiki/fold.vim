" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#fold#level(lnum) " {{{1
  let l:line = getline(a:lnum)

  if l:line =~# '^#\{1,6} [^#]' && !s:is_code(a:lnum)
    return '>' . vimwiki#u#count_first_sym(l:line)
  endif

  if l:line =~# '^```'
    return (s:is_code(a:lnum+1) ? 'a1' : 's1')
  endif

  return '='
endfunction

" }}}1
function! vimwiki#fold#text() "{{{
  let line = getline(v:foldstart)
  let main_text = substitute(line, '^\s*', repeat(' ',indent(v:foldstart)), '')
  let fold_len = v:foldend - v:foldstart + 1
  let len_text = ' ['.fold_len.'] '
  if line !~# g:vimwiki_rxPreStart
    let [main_text, spare_len] = s:shorten_text(main_text, 50)
    return main_text.len_text
  else
    " fold-text for code blocks: use one or two of the starting lines
    let [main_text, spare_len] = s:shorten_text(main_text, 24)
    let line1 = substitute(getline(v:foldstart+1), '^\s*', ' ', '')
    let [content_text, spare_len] = s:shorten_text(line1, spare_len+20)
    if spare_len > 5 && fold_len > 3
      let line2 = substitute(getline(v:foldstart+2), '^\s*', '  ', '')
      let [more_text, spare_len] = s:shorten_text(line2, spare_len+12)
      let content_text .= more_text
    endif
    return main_text.len_text.content_text
  endif
endfunction

"}}}

function! s:shorten_text(text, len) "{{{
  " strlen() returns lenght in bytes, not in characters, so we'll have to do a
  " trick here -- replace all non-spaces with dot, calculate lengths and
  " indexes on it, then use original string to break at selected index.
  let text_pattern = substitute(a:text, '\m\S', '.', 'g')
  let spare_len = a:len - strlen(text_pattern)
  if (spare_len + 5 >= 0)
    return [a:text, spare_len]
  endif

  let newlen = a:len - 3
  let idx = strridx(text_pattern, ' ', newlen + 5)
  let break_idx = (idx + 5 >= newlen) ? idx : newlen
  return [matchstr(a:text, '\m^.\{'.break_idx.'\}') . '...',
        \ newlen - break_idx]
endfunction

"}}}
function! s:is_code(lnum) " {{{1
  return match(map(synstack(a:lnum, 1),
          \        "synIDattr(v:val, 'name')"),
          \    '^\%(textSnip\|VimwikiPre\)') > -1
endfunction

" }}}1

" vim: fdm=marker sw=2
