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
function! vimwiki#page#goto_index() "{{{
  call vimwiki#todo#edit_file('edit',
        \ vimwiki#opts#get('path')
        \ . vimwiki#opts#get('index')
        \ . vimwiki#opts#get('ext'),
        \ '')
endfunction "}}}
function! vimwiki#page#backlinks() "{{{1
  let l:origin = expand("%:p")
  let l:locs = []

  for l:file in vimwiki#base#find_files(0, 0)
    for [l:target, l:dummy, l:lnum, l:col] in s:get_links(l:file)
      if vimwiki#path#is_equal(l:target, l:origin)
            \ && !vimwiki#path#is_equal(l:target, l:file)
        call add(l:locs, {'filename':l:file, 'lnum':l:lnum, 'col':l:col})
      endif
    endfor
  endfor

  if empty(l:locs)
    echomsg 'Vimwiki: No other file links to this file'
  else
    call setloclist(0, l:locs, 'r')
    lopen
  endif
endfunction

"}}}1

"
" TODO
"
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
function! vimwiki#page#create_toc() " {{{1
  " collect new headers
  let is_inside_pre_or_math = 0  " 1: inside pre, 2: inside math, 0: outside
  let headers = []
  let headers_levels = [['', 0], ['', 0], ['', 0], ['', 0], ['', 0], ['', 0]]
  for lnum in range(1, line('$'))
    let line_content = getline(lnum)
    if (is_inside_pre_or_math == 1 && line_content =~# g:vimwiki_rxPreEnd) ||
          \ (is_inside_pre_or_math == 2 && line_content =~# g:vimwiki_rxMathEnd)
      let is_inside_pre_or_math = 0
      continue
    endif
    if is_inside_pre_or_math > 0
      continue
    endif
    if line_content =~# g:vimwiki_rxPreStart
      let is_inside_pre_or_math = 1
      continue
    endif
    if line_content =~# g:vimwiki_rxMathStart
      let is_inside_pre_or_math = 2
      continue
    endif
    if line_content !~# g:vimwiki_rxHeader
      continue
    endif
    let h_level = vimwiki#u#count_first_sym(line_content)
    let h_text = vimwiki#u#trim(matchstr(line_content, g:vimwiki_rxHeader))
    if h_text ==# g:vimwiki_toc_header  " don't include the TOC's header itself
      continue
    endif
    let headers_levels[h_level-1] = [h_text, headers_levels[h_level-1][1]+1]
    for idx in range(h_level, 5) | let headers_levels[idx] = ['', 0] | endfor

    let h_complete_id = ''
    for l in range(h_level-1)
      if headers_levels[l][0] != ''
        let h_complete_id .= headers_levels[l][0].'#'
      endif
    endfor
    let h_complete_id .= headers_levels[h_level-1][0]

    if g:vimwiki_html_header_numbering > 0
          \ && g:vimwiki_html_header_numbering <= h_level
      let h_number = join(map(copy(headers_levels[
            \ g:vimwiki_html_header_numbering-1 : h_level-1]), 'v:val[1]'), '.')
      let h_number .= g:vimwiki_html_header_numbering_sym
      let h_text = h_number.' '.h_text
    endif

    call add(headers, [h_level, h_complete_id, h_text])
  endfor

  let lines = []
  let startindent = repeat(' ', vimwiki#lst#get_list_margin())
  let indentstring = repeat(' ', shiftwidth())
  let bullet = vimwiki#lst#default_symbol().' '
  for [lvl, link, desc] in headers
    let esc_link = substitute(link, "'", "''", 'g')
    let esc_desc = substitute(desc, "'", "''", 'g')
    let link = substitute(g:vimwiki_WikiLinkTemplate2, '__LinkUrl__',
          \ '\='."'".'#'.esc_link."'", '')
    let link = substitute(link, '__LinkDescription__', '\='."'".esc_desc."'", '')
    call add(lines, startindent.repeat(indentstring, lvl-1).bullet.link)
  endfor

  let links_rx = '\m^\s*'.vimwiki#u#escape(vimwiki#lst#default_symbol()).' '

  call vimwiki#base#update_listing_in_buffer(lines, g:vimwiki_toc_header, links_rx,
        \ 1, 1)
endfunction

" }}}1

"
" TODO
"
function! s:get_links(wikifile) "{{{1
  if !filereadable(a:wikifile) | return [] | endif

  let rx_link = g:vimwiki_markdown_wikilink
  let links = []
  let lnum = 0

  for line in readfile(a:wikifile)
    let lnum += 1

    let link_count = 1
    while 1
      let col = match(line, rx_link, 0, link_count)+1
      let link_text = matchstr(line, rx_link, 0, link_count)
      if link_text == ''
        break
      endif
      let link_count += 1
      let target = vimwiki#link#resolve(link_text, a:wikifile)
      if target.filename != '' &&
            \ target.scheme =~# '\mwiki\d\+\|diary\|file\|local'
        call add(links, [target.filename, target.anchor, lnum, col])
      endif
    endwhile
  endfor

  return links
endfunction

"}}}1

" vim: fdm=marker sw=2

