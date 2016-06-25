" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#link#find_next() "{{{1
  call search(g:vimwiki.rx.link_any, 's')
endfunction

" }}}1
function! vimwiki#link#find_prev() "{{{1
  if vimwiki#u#in_syntax('VimwikiLink')
        \ && vimwiki#u#in_syntax('VimwikiLink', line('.'), col('.')-1)
    call search(g:vimwiki.rx.link_any, 'sb')
  endif
  call search(g:vimwiki.rx.link_any, 'sb')
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

function! vimwiki#link#open(cmd, link, ...) " {{{1
  if a:link.filename == ''
    echomsg 'Vimwiki Error: Unable to resolve link!'
    return
  endif

  if a:link.scheme =~# 'wiki\|diary'
    let l:prev_link = []
    let l:update_prev_link = 0
    if !resolve(a:link.filename) ==# resolve(expand('%:p'))
      let l:update_prev_link = 1
      if a:0
        let l:prev_link = [a:1, []]
      elseif &ft ==# 'vimwiki'
        let l:prev_link = [expand('%:p'), getpos('.')]
      endif
    endif
    call vimwiki#todo#edit_file(a:cmd, a:link.filename, a:link.anchor,
          \ l:prev_link, l:update_prev_link)
  else
    call vimwiki#link#system_open(a:link.filename)
  endif
endfunction

" }}}1
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
function! vimwiki#link#resolve(url, ...) " {{{1
  let l:link = {}
  let l:link.origin = a:0 > 0 ? a:1 : expand('%:p')
  let l:link.url = (a:url !~# g:vimwiki.rx.url ? 'wiki:' : '') . a:url
  let l:link.scheme = matchstr(l:link.url, g:vimwiki.rx.match_scheme)
  let l:link.text = matchstr(l:link.url, g:vimwiki.rx.match_url)

  " External link type (e.g. weblink)
  if l:link.scheme !~# 'wiki\|diary\|local\|file'
    return l:link
  endif

  " Extract anchor
  if l:link.scheme =~# 'wiki\|diary'
    let l:anchors = split(l:link.text, '#', 1)
    let l:link.anchor = (len(l:anchors) > 1) && (l:anchors[-1] != '')
          \ ? join(l:anchors[1:], '#') : ''
    let l:link.text = empty(l:anchors[0])
          \ ? fnamemodify(l:link.origin, ':p:t:r')
          \ : l:anchors[0]
  endif

  " check if absolute or relative path
  if l:link.scheme ==# 'wiki' && l:link.text[0] == '/'
    if l:link.text != '/'
      let l:link.text = l:link.text[1:]
    endif
    let l:relative = 0
  elseif l:link.scheme !=# 'wiki' && l:link.text =~# '\m^/\|\~/'
    let l:relative = 0
  else
    let l:relative = 1
    let l:root = fnamemodify(l:link.origin, ':p:h') . '/'
  endif

  " extract the other items depending on the scheme
  if l:link.scheme ==# 'wiki'
    let l:link.filename = (!l:relative ? g:vimwiki.root : l:root)
          \ . l:link.text . '.wiki'
  elseif l:link.scheme ==# 'diary'
    let l:link.filename = g:vimwiki.diary . l:link.text . '.wiki'
  elseif l:link.scheme =~# 'file\|local'
    let l:link.filename = simplify(l:relative
          \ ? l:root . l:link_text
          \ : fnamemodify(l:link.text, ':p'))
  endif

  return l:link
endfunction

" }}}1

function! vimwiki#link#normalize(...) " {{{1
  if a:0 == 0
    call s:normalize_link_syntax_n()
  elseif visualmode() ==# 'v' && line("'<") == line("'>")
    call s:normalize_link_syntax_v()
  endif
endfunction

" }}}1
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
  let lnk = s:matchstr_at_cursor(g:vimwiki.rx.link_wiki0)
  if !empty(lnk)
    let sub = vimwiki#link#normalize_helper(lnk,
          \ g:vimwiki.rx.link_wiki_url, g:vimwiki.rx.link_wiki_text,
          \ g:vimwiki_WikiLink1Template2)
    call s:replacestr_at_cursor(g:vimwiki.rx.link_wiki0, sub)
    return
  endif
  
  " try WikiLink1: replace with WikiLink0
  let lnk = s:matchstr_at_cursor(g:vimwiki.rx.link_wiki1)
  if !empty(lnk)
    let sub = vimwiki#link#normalize_helper(lnk,
          \ g:vimwiki.rx.link_wiki_url, g:vimwiki.rx.link_wiki_text,
          \ g:vimwiki_WikiLinkTemplate2)
    call s:replacestr_at_cursor(g:vimwiki.rx.link_wiki1, sub)
    return
  endif
  
  " try Weblink
  let lnk = s:matchstr_at_cursor(g:vimwiki.rx.link_web)
  if !empty(lnk)
    let sub = vimwiki#link#normalize_helper(lnk,
          \ g:vimwiki.rx.link_web_url, g:vimwiki.rx.link_web_text,
          \ g:vimwiki_Weblink1Template)
    call s:replacestr_at_cursor(g:vimwiki.rx.link_web, sub)
    return
  endif

  " try Word (any characters except separators)
  " rxWord is less permissive than rxWikiLinkUrl which is used in
  " normalize_link_syntax_v
  let lnk = s:matchstr_at_cursor(g:vimwiki.rx.word)
  if !empty(lnk)
    let sub = vimwiki#link#normalize_helper(lnk,
          \ g:vimwiki.rx.word, '',
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
    let rxUrl = g:vimwiki.rx.word
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

function! vimwiki#link#follow(split) "{{{1
  if a:split ==# 'split'
    let cmd = ':split '
  elseif a:split ==# 'vsplit'
    let cmd = ':vsplit '
  else
    let cmd = ':e '
  endif

  let lnk = matchstr(
        \ s:matchstr_at_cursor(g:vimwiki.rx.link_wiki),
        \ g:vimwiki.rx.link_wiki_url)

  if empty(lnk)
    let lnk = matchstr(
          \ s:matchstr_at_cursor(g:vimwiki.rx.link_web),
          \ g:vimwiki.rx.link_web_url)
  endif

  if !empty(lnk)
    let l:link = vimwiki#link#resolve(lnk)
    PP l:link

    if s:link_handler(l:link) | return | endif
    if s:reflink_follow(l:link) | return | endif

    call vimwiki#link#open(cmd, l:link)
    return
  endif

  call vimwiki#link#normalize()
endfunction

" }}}
function! s:link_handler(link) " {{{1
  let lnk = expand(a:link.url)
  if filereadable(lnk) && fnamemodify(lnk, ':e') ==? 'pdf'
    silent execute '!zathura ' lnk '&'
    return 1
  endif

  if a:link.scheme ==# 'file'
    let fname = a:link.url
    if isdirectory(fname)
      execute 'Unite file:' . fname
      return 1
    elseif filereadable(fname)
      execute 'edit' fname
      return 1
    endif
  endif

  if a:link.scheme ==# 'doi'
    silent execute '!xdg-open http://dx.doi.org/' . a:link.text .'&'
    return 1
  endif

  return 0
endfunction

"}}}1
"
" TODO - doesn't work
"
function! s:reflink_follow(link) " {{{1
  if !exists('b:vimwiki')
    let b:vimwiki = {}
  endif

  if !has_key(b:vimwiki, 'reflinks')
    let b:vimwiki.reflinks = s:reflink_scan()
  endif

  if has_key(b:vimwiki.reflinks, a:link.url)
    call vimwiki#link#system_open(b:vimwiki.reflinks[a:link])
    return 1
  endif

  return 0
endfunction

" }}}1
function! s:reflink_scan() " {{{1
  let l:refs = {}

  try
    " Why noautocmd? Because https://github.com/vimwiki/vimwiki/issues/121
    noautocmd execute 'vimgrep #'.g:vimwiki.rx.mkd_ref.'#j %'
  catch /^Vim\%((\a\+)\)\=:E480/
  endtry

  for d in getqflist()
    let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
    let descr = matchstr(matchline, g:vimwiki.rx.mkd_ref_text)
    let url = matchstr(matchline, g:vimwiki.rx.mkd_ref_url)
    if descr != '' && url != ''
      let l:refs[descr] = url
    endif
  endfor

  return l:refs
endfunction

" }}}1

function! s:matchstr_at_cursor(regex) " {{{1
  let l:c1 = searchpos(a:regex, 'ncb', line('.'))[1]
  let l:c2 = searchpos(a:regex, 'nce', line('.'))[1]

  return (l:c1 > 0) && (l:c2 > 0)
        \ ? strpart(getline('.'), l:c1-1, l:c2)
        \ : ''
endfunction

"}}}1
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
