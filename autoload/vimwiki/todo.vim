" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#todo#edit_file(command, filename, anchor, ...) "{{{1
  let fname = escape(a:filename, '% *|#')
  let dir = fnamemodify(a:filename, ":p:h")

  let ok = vimwiki#path#mkdir(dir, 1)

  if !ok
    echomsg ' '
    echomsg 'Vimwiki Error: Unable to edit file in non-existent directory: '.dir
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
function! vimwiki#todo#open_link(cmd, link, ...) "{{{
  let link_infos = vimwiki#link#resolve(a:link)

  if link_infos.filename == ''
    echomsg 'Vimwiki Error: Unable to resolve link!'
    return
  endif

  let is_wiki_link = link_infos.scheme =~# '\mwiki\d\+'
        \ || link_infos.scheme =~# 'diary'

  let update_prev_link = is_wiki_link &&
        \ !resolve(link_infos.filename) ==# resolve(expand('%:p'))

  let vimwiki_prev_link = []
  " update previous link for wiki pages
  if update_prev_link
    if a:0
      let vimwiki_prev_link = [a:1, []]
    elseif &ft ==# 'vimwiki'
      let vimwiki_prev_link = [expand('%:p'), getpos('.')]
    endif
  endif

  " open/edit
  if is_wiki_link
    call vimwiki#todo#edit_file(a:cmd, link_infos.filename, link_infos.anchor,
          \ vimwiki_prev_link, update_prev_link)
    if link_infos.index != 0
      " this call to setup_buffer_state may not be necessary
      call vimwiki#todo#setup_buffer_state(link_infos.index)
    endif
  else
    call vimwiki#base#system_open_link(link_infos.filename)
  endif
endfunction " }}}
function! vimwiki#todo#subdir(path, filename) "{{{
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
endfunction "}}}
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

function! s:jump_to_anchor(anchor) "{{{
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
endfunction "}}}

" vim: fdm=marker sw=2
