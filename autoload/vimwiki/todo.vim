" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#todo#edit_file(command, filename, anchor, ...) "{{{1
  let fname = escape(a:filename, '% *|#')
  let dir = fnamemodify(a:filename, ":p:h")

  if !isdirectory(dir)
    echom 'Vimwiki Error: Unable to edit file in non-existent directory: '.dir
    return
  endif

  " check if the file we want to open is already the current file
  " which happens if we jump to an achor in the current file.
  " This hack is necessary because apparently Vim messes up the result of
  " getpos() directly after this command. Strange.
  if !(a:command ==# ':e ' && resolve(a:filename) ==# resolve(expand('%:p')))
    execute a:command.' '.fname
    " Make sure no other plugin takes ownership over the new file. Vimwiki
    " rules them all! Well, except for directories, which may be opened with
    " Netrw
    if &filetype != 'vimwiki' && fname !~ '\m/$'
      set filetype=vimwiki
    endif
  endif
  if a:anchor != ''
    call s:jump_to_anchor(a:anchor)
  endif

  " save previous link
  " a:1 -- previous vimwiki link to save
  " a:2 -- should we update previous link
  if a:0 && a:2 && len(a:1) > 0
    if !exists('b:vimwiki')
      let b:vimwiki = {}
    endif
    let b:vimwiki.prev_link = a:1
  endif
endfunction

" }}}1
function! vimwiki#todo#subdir(path, filename) "{{{1
  let path = a:path
  " ensure that we are not fooled by a symbolic link
  "FIXME if we are not "fooled", we end up in a completely different wiki?
  if a:filename !~# '^scp:'
    let filename = resolve(a:filename)
  else
    let filename = a:filename
  endif
  let idx = 0
  "FIXME this can terminate in the middle of a path component!
  while path[idx] ==? filename[idx]
    let idx = idx + 1
  endwhile

  let p = split(strpart(filename, idx), '[/\\]')
  let res = join(p[:-2], '/')
  if len(res) > 0
    let res = res.'/'
  endif
  return res
endfunction

"}}}1
function! vimwiki#todo#apply_template(template, rxUrl, rxDesc, rxStyle) " {{{1
  let lnk = a:template
  if a:rxUrl != ""
    let lnk = substitute(lnk, '__LinkUrl__', '\='."'".a:rxUrl."'", 'g')
  endif
  if a:rxDesc != ""
    let lnk = substitute(lnk, '__LinkDescription__', '\='."'".a:rxDesc."'", 'g')
  endif
  if a:rxStyle != ""
    let lnk = substitute(lnk, '__LinkStyle__', '\='."'".a:rxStyle."'", 'g')
  endif
  return lnk
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
