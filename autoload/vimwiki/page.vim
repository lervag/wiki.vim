" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#page#delete() "{{{1
  if input('Delete "' . expand('%') . '" [y]es/[N]o? ') !~? '^y'
        \ | return | endif

  let l:filename = expand('%:p')
  try
    call delete(l:filename)
  catch /.*/
    echomsg 'Vimwiki Error: Cannot delete "' . expand('%:t:r') . '"!'
    return
  endtry

  call vimwiki#link#go_back()
  execute 'bdelete! ' . escape(l:filename, " ")

  " reread buffer => deleted wiki link should appear as non-existent
  if !empty(expand('%:p')) | edit | endif
endfunction

"}}}1
function! vimwiki#page#rename() "{{{1
  let subdir = vimwiki#opts#get('subdir')
  let old_fname = subdir . expand('%:t')

  " there is no file (new one maybe)
  if glob(expand('%:p')) == ''
    echomsg 'Vimwiki Error: Cannot rename "'.expand('%:p').
          \'". It does not exist! (New file? Save it before renaming.)'
    return
  endif

  let val = input('Rename "'.expand('%:t:r').'" [y]es/[N]o? ')
  if val !~? '^y'
    return
  endif

  let new_link = input('Enter new name: ')

  if new_link =~# '[/\\]'
    " It is actually doable but I do not have free time to do it.
    echomsg 'Vimwiki Error: Cannot rename to a filename with path!'
    return
  endif

  " check new_fname - it should be 'good', not empty
  if substitute(new_link, '\s', '', 'g') == ''
    echomsg 'Vimwiki Error: Cannot rename to an empty filename!'
    return
  endif

  let url = matchstr(new_link, g:vimwiki_rxWikiLinkMatchUrl)
  if url != ''
    let new_link = url
  endif

  let new_link = subdir.new_link
  let new_fname = vimwiki#opts#get('path').new_link.vimwiki#opts#get('ext')

  " do not rename if file with such name exists
  let fname = glob(new_fname)
  if fname != ''
    echomsg 'Vimwiki Error: Cannot rename to "'.new_fname.
          \ '". File with that name exist!'
    return
  endif
  " rename wiki link file
  try
    echomsg 'Vimwiki: Renaming '.vimwiki#opts#get('path').old_fname.' to '.new_fname
    let res = rename(expand('%:p'), expand(new_fname))
    if res != 0
      throw "Cannot rename!"
    end
  catch /.*/
    echomsg 'Vimwiki Error: Cannot rename "'.expand('%:t:r').'" to "'.new_fname.'"'
    return
  endtry

  let &buftype="nofile"

  let cur_buffer = [expand('%:p'),
        \getbufvar(expand('%:p'), "vimwiki_prev_link")]

  let blist = s:get_wiki_buffers()

  " save wiki buffers
  for bitem in blist
    execute ':b '.escape(bitem[0], ' ')
    execute ':update'
  endfor

  execute ':b '.escape(cur_buffer[0], ' ')

  " remove wiki buffers
  for bitem in blist
    execute 'bwipeout '.escape(bitem[0], ' ')
  endfor

  let setting_more = &more
  setlocal nomore

  " update links
  call s:update_wiki_links(s:tail_name(old_fname), new_link)

  " restore wiki buffers
  for bitem in blist
    if !vimwiki#path#is_equal(bitem[0], cur_buffer[0])
      call s:open_wiki_buffer(bitem)
    endif
  endfor

  call s:open_wiki_buffer([new_fname,
        \ cur_buffer[1]])
  " execute 'bwipeout '.escape(cur_buffer[0], ' ')

  echomsg 'Vimwiki: '.old_fname.' is renamed to '.new_fname

  let &more = setting_more
endfunction

" }}}1

" vim: fdm=marker sw=2

