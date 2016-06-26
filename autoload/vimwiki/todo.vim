" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#todo#edit_file(filename, ...) "{{{1
  let l:dir = fnamemodify(a:filename, ':p:h')
  if !isdirectory(l:dir)
    echom 'Vimwiki Error: Unable to edit file in non-existent directory:' l:dir
    return
  endif

  let l:opts = a:0 > 0 ? a:1 : {}
  if resolve(a:filename) !=# resolve(expand('%:p'))
    execute get(l:opts, 'cmd', 'edit') fnameescape(a:filename)
  endif

  if !empty(get(l:opts, 'anchor', ''))
    call s:jump_to_anchor(l:opts.anchor)
  endif

  if has_key(l:opts, 'prev_link')
    let b:vimwiki.prev_link = l:opts.prev_link
  endif
endfunction

" }}}1
function! vimwiki#todo#apply_template(template, rxUrl, rxDesc, rxStyle) " {{{1
  let l:lnk = a:template

  if !empty(a:rxUrl)
    let l:lnk = substitute(l:lnk, '__LinkUrl__',
          \ '\=''' . a:rxUrl . '''', 'g')
  endif

  if !empty(a:rxDesc)
    let l:lnk = substitute(l:lnk, '__LinkDescription__',
          \ '\=''' . a:rxDesc . '''', 'g')
  endif

  if !empty(a:rxStyle)
    let l:lnk = substitute(l:lnk, '__LinkStyle__',
          \ '\=''' . a:rxStyle . '''', 'g')
  endif

  return l:lnk
endfunction

" }}}1

function! s:jump_to_anchor(anchor) " {{{1
  let oldpos = getpos('.')
  call cursor(1, 1)

  let anchor = vimwiki#u#escape(a:anchor)

  let segments = split(anchor, '#', 0)
  for segment in segments

    let anchor_header = substitute(
          \ g:vimwiki_markdown_header_match,
          \ '__Header__', "\\='".segment."'", '')
    let anchor_bold = substitute(g:vimwiki_markdown_bold_match,
          \ '__Text__', "\\='".segment."'", '')
    let anchor_tag = substitute(g:vimwiki_markdown_tag_match,
          \ '__Tag__', "\\='".segment."'", '')

    if         !search(anchor_tag, 'Wc')
          \ && !search(anchor_header, 'Wc')
          \ && !search(anchor_bold, 'Wc')
      call setpos('.', oldpos)
      break
    endif
    let oldpos = getpos('.')
  endfor
endfunction

" }}}1

" vim: fdm=marker sw=2
