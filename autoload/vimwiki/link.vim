" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" TODO
" - reference links don't work
" - Add normlize_link_in_diary?
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
function! vimwiki#link#resolve(url, ...) " {{{1
  let l:link = {}
  let l:link.origin = a:0 > 0 ? a:1 : expand('%:p')

  " Decompose link into its scheme and link text
  let l:decompose = matchlist(a:url, '\v((\w+):%(//)?)?(.*)')
  if empty(l:decompose[2])
    let l:link.scheme = 'wiki'
    let l:link.url = 'wiki:' . a:url
  else
    let l:link.scheme = l:decompose[2]
    let l:link.url = a:url
  endif
  let l:link.text = l:decompose[3]

  " This is enough for external links, such as weblinks
  if l:link.scheme !~# 'wiki\|diary\|local\|file'
    return l:link
  endif

  " Extract anchor
  if l:link.scheme =~# 'wiki\|diary'
    let l:anchors = split(l:link.text, '#', 1)
    let l:link.anchor = (len(l:anchors) > 1) && (l:anchors[-1] != '')
          \ ? join(l:anchors[1:], '#') : ''
    let l:link.text = !empty(l:anchors[0]) ? l:anchors[0]
          \ : fnamemodify(l:link.origin, ':p:t:r')
  endif

  " Extract target filename (full path)
  let l:root = fnamemodify(l:link.origin, ':p:h') . '/'
  if l:link.scheme ==# 'wiki'
    if l:link.text[0] == '/'
      let l:link.text = strpart(l:link.text, 1)
      let l:link.filename = g:vimwiki.root . l:link.text . '.wiki'
    else
      let l:link.filename = l:root . l:link.text . '.wiki'
    endif
  elseif l:link.scheme ==# 'diary'
    let l:link.filename = g:vimwiki.diary . l:link.text . '.wiki'
  else
    if l:link.text[0] ==# '/'
      let l:link.filename = l:link.text
    elseif l:link.text =~# '\~\w*\/'
      let l:link.filename = simplify(fnamemodify(l:link.text, ':p'))
    else
      let l:link.filename = simplify(l:root . l:link.text)
    endif
  endif

  return l:link
endfunction

" }}}1
function! vimwiki#link#open(cmd, link, ...) " {{{1
  call s:follow_link_wiki(a:link, a:cmd, a:000)
endfunction

" }}}1
function! vimwiki#link#follow(...) "{{{1
  " Argument supplied specifies command used to open link
  let l:cmd = a:0 > 0 ? a:1 : 'edit'

  "
  " Get link - either wikilink or weblink
  "
  let l:lnk = matchstr(s:matchstr_at_cursor(g:vimwiki.rx.link_wiki),
        \              g:vimwiki.rx.link_wiki_url)
  if empty(l:lnk)
    let l:lnk = matchstr(s:matchstr_at_cursor(g:vimwiki.rx.link_web),
          \              g:vimwiki.rx.link_web_url)
  endif

  "
  " If no link found, normalize current word
  "
  if empty(l:lnk)
    call vimwiki#link#normalize()
    return
  endif

  "
  " Try various link handlers
  "
  let l:link = vimwiki#link#resolve(l:lnk)
  if s:follow_link_wiki(l:link, l:cmd) | return | endif
  if s:follow_link_reference(l:link) | return | endif

  call s:follow_link_external(l:link)
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
function! vimwiki#link#get_backlinks() "{{{1
  let l:origin = expand("%:p")
  let l:locs = []

  for l:file in globpath(g:vimwiki.root, '**/*.wiki', 0, 1)
    if resolve(l:file) ==# resolve(l:origin) | break | endif

    for l:link in vimwiki#link#get_from_file(l:file)
      if resolve(l:link.filename) ==# resolve(l:origin)
        call add(l:locs, {
              \ 'filename' : l:file,
              \ 'text' : empty(l:link.anchor) ? '' : 'Anchor: ' . l:anchor,
              \ 'lnum' : l:link.lnum,
              \ 'col' : l:link.col
              \})
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


function! s:follow_link_wiki(link, cmd, ...) " {{{1
  if a:link.scheme !~# 'wiki\|diary' | return 0 | endif

  let l:opts = {}

  if resolve(a:link.filename) !=# resolve(expand('%:p'))
    if a:0 > 0
      let l:opts.prev_link = [a:1, []]
    elseif &ft ==# 'vimwiki'
      let l:opts.prev_link = [expand('%:p'), getpos('.')]
    endif
  endif

  let l:opts.anchor = a:link.anchor
  let l:opts.cmd = a:cmd
  call vimwiki#edit_file(a:link.filename, l:opts)
  return 1
endfunction

"}}}1
function! s:follow_link_reference(link) " {{{1
  return 0

  if !has_key(b:vimwiki, 'reflinks')
    let b:vimwiki.reflinks = {}

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
        let b:vimwiki.reflinks[descr] = url
      endif
    endfor
  endif

  if !has_key(b:vimwiki.reflinks, a:link.url) | return 0 | endif

  call vimwiki#link#system_open(b:vimwiki.reflinks[a:link])
  return 1
endfunction

" }}}1
function! s:follow_link_external(link) " {{{1
  if a:link.scheme =~# 'file\|local'
    if isdirectory(a:link.filename)
      execute 'Unite file:' . a:link.filename
      return 1
    endif

    if !filereadable(a:link.filename) | return 0 | endif

    if a:link.filename =~# 'pdf$'
      silent execute '!zathura' a:link.filename '&'
      return 1
    endif

    execute 'edit' a:link.filename
    return 1
  endif

  if a:link.scheme ==# 'doi'
    silent execute '!xdg-open http://dx.doi.org/' . a:link.text '&'
    return 1
  endif

  call system('xdg-open ' . shellescape(a:link.url) . '&')
endfunction

"}}}1

function! s:normalize_link_syntax_n() " {{{
  let lnum = line('.')

  " try WikiLink0: replace with WikiLink1
  let lnk = s:matchstr_at_cursor(g:vimwiki.rx.link_wiki0)
  if !empty(lnk)
    let sub = s:normalize_helper(lnk,
          \ g:vimwiki.rx.link_wiki_url, g:vimwiki.rx.link_wiki_text,
          \ g:vimwiki_WikiLink1Template2)
    call s:replacestr_at_cursor(g:vimwiki.rx.link_wiki0, sub)
    return
  endif
  
  " try WikiLink1: replace with WikiLink0
  let lnk = s:matchstr_at_cursor(g:vimwiki.rx.link_wiki1)
  if !empty(lnk)
    let sub = s:normalize_helper(lnk,
          \ g:vimwiki.rx.link_wiki_url, g:vimwiki.rx.link_wiki_text,
          \ g:vimwiki_WikiLinkTemplate2)
    call s:replacestr_at_cursor(g:vimwiki.rx.link_wiki1, sub)
    return
  endif
  
  " try Weblink
  let lnk = s:matchstr_at_cursor(g:vimwiki.rx.link_web)
  if !empty(lnk)
    let sub = s:normalize_helper(lnk,
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
    let sub = s:normalize_helper(lnk,
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
function! s:normalize_helper(str, rxUrl, rxDesc, template) " {{{1
  let l:url = matchstr(a:str, a:rxUrl)
  let l:descr = matchstr(a:str, a:rxDesc)
  if empty(l:descr)
    let l:descr = s:clean_url(l:url)
  endif

  return substitute(
        \ substitute(a:template,
        \   '__LinkDescription__', '\="' . l:descr . '"', ''),
        \ '__LinkUrl__', '\="' . l:url . '"', '')
endfunction

" }}}1
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

  return s:normalize_helper(str, rxUrl, rxDesc, template)
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
