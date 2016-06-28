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

function! vimwiki#link#get_at_cursor() " {{{1
  let l:lnk = matchstr(s:matchstr_at_cursor(g:vimwiki.rx.link_wiki),
        \              g:vimwiki.rx.link_wiki_url)
  if empty(l:lnk)
    let l:lnk = matchstr(s:matchstr_at_cursor(g:vimwiki.rx.link_web),
          \              g:vimwiki.rx.link_web_url)
  endif

  return empty(l:lnk) ? {} : vimwiki#link#parse(l:lnk)
endfunction

" }}}1
function! vimwiki#link#parse(url, ...) " {{{1
  let l:link = {}
  let l:link.url = a:url
  let l:link.origin = a:0 > 0 ? a:1 : expand('%:p')

  " Decompose link into its scheme and link text
  let l:link_parts = matchlist(a:url, '\v((\w+):%(//)?)?(.*)')
  let l:link.text = l:link_parts[3]
  if empty(l:link_parts[2])
    let l:link.scheme = 'wiki'
    let l:link.url = 'wiki:' . a:url
  else
    let l:link.scheme = l:link_parts[2]
  endif

  return extend(l:link,
        \ get({
        \     'wiki':  s:parse_link_wiki(l:link),
        \     'diary': s:parse_link_wiki(l:link),
        \     'file':  s:parse_link_file(l:link),
        \     'doi':   s:parse_link_doi(l:link),
        \   }, l:link.scheme,
        \   s:parse_link_external(l:link)),
        \ 'force')
endfunction

" }}}1
function! vimwiki#link#follow(...) "{{{1
  let l:link = vimwiki#link#get_at_cursor()

  if empty(l:link)
    call vimwiki#link#normalize()
  else
    call call(l:link.follow, a:000)
  endif
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

function! s:parse_link_wiki(link) " {{{1
  let l:link = {}
  let l:link.follow = function('s:follow_link_wiki')

  " Parse link anchor
  let l:anchors = split(a:link.text, '#', 1)
  let l:link.anchor = (len(l:anchors) > 1) && (l:anchors[-1] != '')
        \ ? join(l:anchors[1:], '#') : ''
  let l:link.text = !empty(l:anchors[0]) ? l:anchors[0]
        \ : fnamemodify(a:link.origin, ':p:t:r')

  " Extract target filename (full path)
  if a:link.scheme ==# 'diary'
    let l:link.scheme = 'wiki'
    let l:link.filename = g:vimwiki.diary . l:link.text . '.wiki'
  else
    if a:link.text[0] == '/'
      let l:link.text = strpart(l:link.text, 1)
      let l:link.filename = g:vimwiki.root . l:link.text . '.wiki'
    else
      let l:link.filename = fnamemodify(a:link.origin, ':p:h') . '/'
            \ . l:link.text . '.wiki'
    endif
  endif

  return l:link
endfunction

" }}}1
function! s:parse_link_file(link) " {{{1
  if a:link.text[0] ==# '/'
    let l:filename = a:link.text
  elseif a:link.text =~# '\~\w*\/'
    let l:filename = simplify(fnamemodify(a:link.text, ':p'))
  else
    let l:filename = simplify(
          \ fnamemodify(a:link.origin, ':p:h') . '/' . a:link.text)
  endif

  return { 'follow' : function('s:follow_link_file'),
        \  'filename' : l:filename }
endfunction

" }}}1
function! s:parse_link_doi(link) " {{{1
  return { 'follow' : function('s:follow_link_doi') }
endfunction

" }}}1
function! s:parse_link_external(link) " {{{1
  return { 'follow' : function('s:follow_link_external') }
endfunction

" }}}1

function! s:follow_link_wiki(...) dict " {{{1
  let l:opts = {}
  let l:opts.cmd = a:0 > 0 ? a:1 : 'edit'
  let l:opts.anchor = self.anchor

  if resolve(self.filename) !=# resolve(expand('%:p'))
    if a:0 > 1
      let l:opts.prev_link = [a:2, []]
    elseif &ft ==# 'vimwiki'
      let l:opts.prev_link = [expand('%:p'), getpos('.')]
    endif
  endif

  call vimwiki#edit_file(self.filename, l:opts)

"   if !has_key(b:vimwiki, 'reflinks')
"     let b:vimwiki.reflinks = {}

"     try
"       " Why noautocmd? Because https://github.com/vimwiki/vimwiki/issues/121
"       noautocmd execute 'vimgrep #'.g:vimwiki.rx.mkd_ref.'#j %'
"     catch /^Vim\%((\a\+)\)\=:E480/
"     endtry

"     for d in getqflist()
"       let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
"       let descr = matchstr(matchline, g:vimwiki.rx.mkd_ref_text)
"       let url = matchstr(matchline, g:vimwiki.rx.mkd_ref_url)
"       if descr != '' && url != ''
"         let b:vimwiki.reflinks[descr] = url
"       endif
"     endfor
"   endif

"   if has_key(b:vimwiki.reflinks, self.url)
"     call s:follow_link_external(b:vimwiki.reflinks[self.url])
"   endif
endfunction

"}}}1
function! s:follow_link_file(...) dict " {{{1
  if isdirectory(self.filename)
    execute 'Unite file:' . self.filename
    return
  endif

  if !filereadable(self.filename) | return | endif

  if self.filename =~# 'pdf$'
    silent execute '!zathura' self.filename '&'
    return
  endif

  execute 'edit' self.filename
endfunction

"}}}1
function! s:follow_link_doi(...) dict " {{{1
  silent execute '!xdg-open http://dx.doi.org/' . self.text '&'
endfunction

"}}}1
function! s:follow_link_external(...) dict " {{{1
  call system('xdg-open ' . shellescape(a:link.url) . '&')
endfunction

"}}}1

function! s:normalize_link_syntax_n() " {{{1
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

endfunction

" }}}1
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
