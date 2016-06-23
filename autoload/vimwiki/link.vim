" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#link#find_next() "{{{1
  call search(g:vimwiki_rxAnyLink, 's')
endfunction

" }}}1
function! vimwiki#link#find_prev() "{{{1
  if vimwiki#u#in_syntax('VimwikiLink')
        \ && vimwiki#u#in_syntax('VimwikiLink', line('.'), col('.')-1)
    call search(g:vimwiki_rxAnyLink, 'sb')
  endif
  call search(g:vimwiki_rxAnyLink, 'sb')
endfunction

" }}}1
function! vimwiki#link#go_back() "{{{1
  if exists('b:vimwiki.prev_link')
    let [l:file, l:pos] = b:vimwiki.prev_link
    execute ':e ' . substitute(l:file, '\s', '\\\0', 'g')
    call setpos('.', l:pos)
  else
    silent! pop!
  endif
endfunction

" }}}1

function! vimwiki#link#open(cmd, link, ...) "{{{
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
    call vimwiki#link#system_open(link_infos.filename)
  endif
endfunction " }}}
function! vimwiki#link#system_open(url) " {{{1
  call system('xdg-open ' . shellescape(a:url) . '&')
endfunction

" }}}1

function! vimwiki#link#get_from_file(file) "{{{1
  if !filereadable(a:file) | return [] | endif

  " TODO: Should match more types of links
  let l:rx_link = g:vimwiki_markdown_wikilink

  let l:links = []
  let l:lnum = 0
  for l:line in readfile(a:file)
    let l:lnum += 1
    let l:count = 0
    while 1
      let l:count += 1
      let l:col = match(l:line, l:rx_link, 0, l:count)+1
      if l:col <= 0 | break | endif

      let l:link = extend(
            \ { 'lnum' : l:lnum, 'col' : l:col },
            \ vimwiki#link#resolve(
            \   matchstr(l:line, l:rx_link, 0, l:count),
            \   a:file))

      if !empty(l:link.filename)
        call add(l:links, l:link)
      endif
    endwhile
  endfor

  return l:links
endfunction

"}}}1

" TODO
function! vimwiki#link#resolve(link_text, ...) " {{{1
  " If the second parameter is present, which should be an absolute file path,
  " it is assumed that the link appears in that file. Without it, the current
  " file is used.
  let l:origin = a:0 > 0 ? a:1 : expand('%:p')

  let link_text = a:link_text

  " if link is schemeless add wikiN: scheme
  if link_text !~# g:vimwiki.rx.url
    let link_text = 'wiki0:'.link_text
  endif

  let l:link = {
        \ 'index': -1,
        \ 'scheme': '',
        \ 'filename': '',
        \ 'anchor': '',
        \ }

  " extract scheme
  let l:link.scheme = matchstr(link_text, g:vimwiki.rx.match_scheme)
  if l:link.scheme == '' || link_text == ''
    let l:link.filename = ''   " malformed link
    return l:link
  endif
  if l:link.scheme !~# '\mwiki\d\+\|diary\|local\|file'
    let l:link.filename = link_text  " unknown scheme, may be a weblink
    return l:link
  endif
  let link_text = matchstr(link_text, g:vimwiki.rx.match_url)

  let is_wiki_link = l:link.scheme =~# '\mwiki\d\+' ||
        \ l:link.scheme ==# 'diary'

  " extract anchor
  if is_wiki_link
    let split_lnk = split(link_text, '#', 1)
    let link_text = split_lnk[0]
    if len(split_lnk) > 1 && split_lnk[-1] != ''
      let l:link.anchor = join(split_lnk[1:], '#')
    endif
    if link_text == ''  " because the link was of the form '#anchor'
      let link_text = fnamemodify(l:origin, ':p:t:r')
    endif
  endif

  " check if absolute or relative path
  if is_wiki_link && link_text[0] == '/'
    if link_text != '/'
      let link_text = link_text[1:]
    endif
    let is_relative = 0
  elseif !is_wiki_link && link_text =~# '\m^/\|\~/'
    let is_relative = 0
  else
    let is_relative = 1
    let root_dir = fnamemodify(l:origin, ':p:h') . '/'
  endif

  " extract the other items depending on the scheme
  if l:link.scheme =~# '\mwiki\d\+'
    let l:link.index = eval(matchstr(l:link.scheme, '\D\+\zs\d\+\ze'))
    if l:link.index < 0 || l:link.index >= 1
      let l:link.filename = ''
      return l:link
    endif

    if !is_relative || l:link.index != 0
      let root_dir = g:vimwiki.root
    endif

    let l:link.filename = root_dir . link_text

    if link_text !~# '\m[/\\]$'
      let l:link.filename .= '.wiki'
    endif

  elseif l:link.scheme ==# 'diary'
    let l:link.index = 0
    let l:link.filename = g:vimwiki.diary . link_text . '.wiki'
  elseif (l:link.scheme ==# 'file' || l:link.scheme ==# 'local')
        \ && is_relative
    let l:link.filename = simplify(root_dir . link_text)
  else " absolute file link
    " collapse repeated leading "/"'s within a link
    let link_text = substitute(link_text, '\m^/\+', '/', '')
    " expand ~/
    let link_text = fnamemodify(link_text, ':p')
    let l:link.filename = simplify(link_text)
  endif

  return l:link
endfunction

" }}}1

function! vimwiki#link#normalize(is_visual_mode) "{{{
  if !a:is_visual_mode
    call s:normalize_link_syntax_n()
  elseif visualmode() ==# 'v' && line("'<") == line("'>")
    call s:normalize_link_syntax_v()
  endif
endfunction "}}}
function! vimwiki#link#normalize_helper(str, rxUrl, rxDesc, template) " {{{1
  let str = a:str
  let url = matchstr(str, a:rxUrl)
  let descr = matchstr(str, a:rxDesc)
  let template = a:template
  if descr == ""
    let descr = s:clean_url(url)
  endif
  let lnk = substitute(template, '__LinkDescription__', '\="'.descr.'"', '')
  let lnk = substitute(lnk, '__LinkUrl__', '\="'.url.'"', '')
  return lnk
endfunction

" }}}1
function! s:normalize_link_syntax_n() " {{{
  let lnum = line('.')

  " try WikiLink0: replace with WikiLink1
  let lnk = s:matchstr_at_cursor(g:vimwiki_rxWikiLink0)
  if !empty(lnk)
    let sub = vimwiki#link#normalize_helper(lnk,
          \ g:vimwiki_rxWikiLinkMatchUrl, g:vimwiki_rxWikiLinkMatchDescr,
          \ g:vimwiki_WikiLink1Template2)
    call s:replacestr_at_cursor(g:vimwiki_rxWikiLink0, sub)
    return
  endif
  
  " try WikiLink1: replace with WikiLink0
  let lnk = s:matchstr_at_cursor(g:vimwiki_rxWikiLink1)
  if !empty(lnk)
    let sub = vimwiki#link#normalize_helper(lnk,
          \ g:vimwiki_rxWikiLinkMatchUrl, g:vimwiki_rxWikiLinkMatchDescr,
          \ g:vimwiki_WikiLinkTemplate2)
    call s:replacestr_at_cursor(g:vimwiki_rxWikiLink1, sub)
    return
  endif
  
  " try Weblink
  let lnk = s:matchstr_at_cursor(g:vimwiki_rxWeblink)
  if !empty(lnk)
    let sub = vimwiki#link#normalize_helper(lnk,
          \ g:vimwiki_rxWeblinkMatchUrl, g:vimwiki_rxWeblinkMatchDescr,
          \ g:vimwiki_Weblink1Template)
    call s:replacestr_at_cursor(g:vimwiki_rxWeblink, sub)
    return
  endif

  " try Word (any characters except separators)
  " rxWord is less permissive than rxWikiLinkUrl which is used in
  " normalize_link_syntax_v
  let lnk = s:matchstr_at_cursor(g:vimwiki_rxWord)
  if !empty(lnk)
    let sub = vimwiki#link#normalize_helper(lnk,
          \ g:vimwiki_rxWord, '',
          \ g:vimwiki_Weblink1Template)
    call s:replacestr_at_cursor('\V'.lnk, sub)
    return
  endif

endfunction " }}}
function! s:normalize_link_syntax_v() " {{{
  let lnum = line('.')
  let sel_save = &selection
  let &selection = "old"
  let rv = @"
  let rt = getregtype('"')
  let done = 0

  try
    norm! gvy
    let visual_selection = @"
    let link = substitute(g:vimwiki_Weblink1Template, '__LinkUrl__', '\='."'".visual_selection."'", '')
    let link = substitute(link, '__LinkDescription__', '\='."'".visual_selection."'", '')

    call setreg('"', link, 'v')

    " paste result
    norm! `>pgvd

  finally
    call setreg('"', rv, rt)
    let &selection = sel_save
  endtry

endfunction " }}}
function! s:clean_url(url) " {{{1
  let url = split(a:url, '/\|=\|-\|&\|?\|\.')
  let url = filter(url, 'v:val !=# ""')
  let url = filter(url, 'v:val !=# "www"')
  let url = filter(url, 'v:val !=# "com"')
  let url = filter(url, 'v:val !=# "org"')
  let url = filter(url, 'v:val !=# "net"')
  let url = filter(url, 'v:val !=# "edu"')
  let url = filter(url, 'v:val !=# "http\:"')
  let url = filter(url, 'v:val !=# "https\:"')
  let url = filter(url, 'v:val !=# "file\:"')
  let url = filter(url, 'v:val !=# "xml\:"')
  return join(url, " ")
endfunction

" }}}1

" TODO: Add this?
function! s:normalize_link_in_diary(lnk) " {{{1
  let link = a:lnk . '.wiki'
  let link_wiki = g:vimwiki.root . link
  let link_diary = g:vimwiki.diary . link
  let link_exists_in_diary = filereadable(link_diary)
  let link_exists_in_wiki = filereadable(link_wiki)
  let link_is_date = a:lnk =~# '\d\d\d\d-\d\d-\d\d'

  if ! link_exists_in_wiki || link_exists_in_diary || link_is_date
    let str = a:lnk
    let rxUrl = g:vimwiki_rxWord
    let rxDesc = ''
    let template = g:vimwiki_WikiLinkTemplate1
  else
    let depth = len(split(link_diary, '/'))
    let str = repeat('../', depth) . a:lnk . '|' . a:lnk
    let rxUrl = '^.*\ze|'
    let rxDesc = '|\zs.*$'
    let template = g:vimwiki_WikiLinkTemplate2
  endif

  return vimwiki#link#normalize_helper(str, rxUrl, rxDesc, template)
endfunction

" }}}1

function! vimwiki#link#follow(split, ...) "{{{1
  if a:split ==# "split"
    let cmd = ":split "
  elseif a:split ==# "vsplit"
    let cmd = ":vsplit "
  elseif a:split ==# "tabnew"
    let cmd = ":tabnew "
  else
    let cmd = ":e "
  endif

  " try WikiLink
  let lnk = matchstr(s:matchstr_at_cursor(g:vimwiki_rxWikiLink),
        \ g:vimwiki_rxWikiLinkMatchUrl)
  " try Weblink
  if lnk == ""
    let lnk = matchstr(s:matchstr_at_cursor(g:vimwiki_rxWeblink),
          \ g:vimwiki_rxWeblinkMatchUrl)
  endif

  if !empty(lnk)
    if s:link_handler(lnk) | return | endif
    if s:reflink_follow(lnk) | return | endif

    " remove the extension from the filename if exists
    let lnk = substitute(lnk, '\.wiki$', '', '')
    call vimwiki#link#open(cmd, lnk)
    return
  endif

  if a:0 > 0
    execute "normal! ".a:1
  else
    call vimwiki#link#normalize(0)
  endif
endfunction

" }}}
function! s:link_handler(link) " {{{1
  let link_info = vimwiki#link#resolve(a:link)

  let lnk = expand(link_info.filename)
  if filereadable(lnk) && fnamemodify(lnk, ':e') ==? 'pdf'
    silent execute '!zathura ' lnk '&'
    return 1
  endif

  if link_info.scheme ==# 'file'
    let fname = link_info.filename
    if isdirectory(fname)
      execute 'Unite file:' . fname
      return 1
    elseif filereadable(fname)
      execute 'edit' fname
      return 1
    endif
  endif

  if link_info.scheme ==# 'doi'
    let url = substitute(link_info.filename, 'doi:', '', '')
    silent execute '!xdg-open http://dx.doi.org/' . url .'&'
    return 1
  endif

  return 0
endfunction

"}}}1
"
" TODO - doesn't work
"
function! s:reflink_follow(link) " {{{1
  if !exists('b:vimwiki.reflinks')
    if !exists('b:vimwiki')
      let b:vimwiki = {}
    endif
    let b:vimwiki.reflinks = s:reflink_scan()
  endif

  if has_key(b:vimwiki.reflinks, a:link)
    call vimwiki#link#system_open(mkd_refs[a:link])
    return 1
  endif

  return 0
endfunction

" }}}1
function! s:reflink_scan() " {{{1
  let mkd_refs = {}

  try
    " Why noautocmd? Because https://github.com/vimwiki/vimwiki/issues/121
    noautocmd execute 'vimgrep #'.g:vimwiki_rxMkdRef.'#j %'
  catch /^Vim\%((\a\+)\)\=:E480/
  endtry

  for d in getqflist()
    let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
    let descr = matchstr(matchline, g:vimwiki_rxMkdRefMatchDescr)
    let url = matchstr(matchline, g:vimwiki_rxMkdRefMatchUrl)
    if descr != '' && url != ''
      let mkd_refs[descr] = url
    endif
  endfor

  return mkd_refs
endfunction

" }}}1

function! s:matchstr_at_cursor(wikiRX) " {{{1
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    return strpart(line, ebeg, elen)
  else
    return ""
  endif
endf "}}}
function! s:replacestr_at_cursor(wikiRX, sub) " {{{1
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    " TODO: There might be problems with Unicode chars...
    let newline = strpart(line, 0, ebeg).a:sub.strpart(line, ebeg+elen)
    call setline(line('.'), newline)
  endif
endf "}}}

" vim: fdm=marker sw=2
