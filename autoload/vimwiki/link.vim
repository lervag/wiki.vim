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
  "
  " Try to match link at cursor position
  "
  for [l:key, l:m] in items(g:vimwiki.link_matcher)
    let l:link = s:matchstr_at_cursor(l:m.rx_full)
    let l:url = matchstr(l:link, l:m.rx_url)
    if !empty(l:url)
      return vimwiki#link#parse(l:url, {
            \ 'default_scheme' : l:m.default_scheme,
            \ 'type' : l:key,
            \ 'text' : matchstr(l:link, l:m.rx_text),
            \})
    endif
  endfor

  "
  " Match ISO dates as diary links
  "
  let l:url = s:matchstr_at_cursor('\d\d\d\d-\d\d-\d\d')
  if !empty(l:url)
    return vimwiki#link#parse(l:url, {
          \ 'default_scheme' : 'diary',
          \ 'type' : 'date',
          \})
  endif

  return {}
endfunction

" }}}1
function! vimwiki#link#parse(url, ...) " {{{1
  let l:options = a:0 > 0 ? a:1 : {}

  let l:link = {}
  let l:link.url = a:url
  let l:link.type = get(l:options, 'type', '')
  let l:link.text = get(l:options, 'text', '')
  let l:link.origin = get(l:options, 'origin', expand('%:p'))

  " Decompose link into its scheme and link text
  let l:link_parts = matchlist(a:url, '\v((\w+):%(//)?)?(.*)')
  let l:link.stripped = l:link_parts[3]
  if empty(l:link_parts[2])
    let l:link.scheme = get(l:options, 'default_scheme', 'wiki')
    let l:link.url = l:link.scheme . ':' . a:url
  else
    let l:link.scheme = l:link_parts[2]
  endif

  let l:link_parsed = get({
        \   'wiki':  s:parse_link_wiki(l:link),
        \   'diary': s:parse_link_wiki(l:link),
        \   'file':  s:parse_link_file(l:link),
        \   'doi':   s:parse_link_doi(l:link),
        \ }, l:link.scheme, s:parse_link_external(l:link))

  return extend(l:link, l:link_parsed, 'force')
endfunction

" }}}1
function! vimwiki#link#follow(...) "{{{1
  let l:link = vimwiki#link#get_at_cursor()

  if empty(l:link)
    call vimwiki#link#normalize_normal()
  else
    call call(l:link.follow, a:000)
  endif
endfunction

" }}}1
function! vimwiki#link#normalize() " {{{1
  "
  " Note: This function assumes that it is called from visual mode.
  "
  let l:save_reg = @a
  let l:parts = split(g:vimwiki.link_matcher.wiki.template[0], '__Url__')
  let l:link = l:parts[0] . getreg('*') . l:parts[1]
  call setreg('a', l:link, 'v')
  normal! gvd"aP
  call setreg('a', l:save_reg)
endfunction

" }}}1
function! vimwiki#link#normalize_normal() " {{{1
  let lnum = line('.')

  let lnk = s:matchstr_at_cursor(g:vimwiki.link_matcher.wiki.rx_full)
  if !empty(lnk)
    let sub = s:normalize_helper(lnk, g:vimwiki.link_matcher.wiki,
          \ g:vimwiki.link_matcher.ref.template[1])
    call s:replacestr_at_cursor(g:vimwiki.link_matcher.wiki.rx_full, sub)
    return
  endif

  let lnk = s:matchstr_at_cursor(g:vimwiki.link_matcher.ref.rx_full)
  if !empty(lnk)
    let sub = s:normalize_helper(lnk, g:vimwiki.link_matcher.ref,
          \ g:vimwiki.link_matcher.wiki.template[1])
    call s:replacestr_at_cursor(g:vimwiki.link_matcher.ref.rx_full, sub)
    return
  endif

  let lnk = s:matchstr_at_cursor(g:vimwiki.link_matcher.url.rx_full)
  if !empty(lnk)
    let sub = s:normalize_helper(lnk, g:vimwiki.link_matcher.url,
          \ g:vimwiki.link_matcher.md.template)
    call s:replacestr_at_cursor(g:vimwiki.link_matcher.url.rx_full, sub)
    return
  endif

  let lnk = s:matchstr_at_cursor(g:vimwiki.rx.word)
  if !empty(lnk)
    let sub = s:normalize_helper(lnk, { 'rx_url' : g:vimwiki.rx.word },
          \ g:vimwiki.link_matcher.wiki.template[1])
    call s:replacestr_at_cursor(g:vimwiki.rx.word, sub)
    return
  endif
endfunction

" }}}1
function! vimwiki#link#toggle() " {{{1
  let l:link = vimwiki#link#get_at_cursor()

  "
  " Trivial case
  "
  if empty(l:link)
    normal! viwy
    call vimwiki#link#normalize()
  endif

  "
  " Get link type
  "
  let l:type = get(l:link, 'type', '')
  if empty(l:type)    | return | endif
  if l:type ==# 'ref' | return | endif

  "
  " Choose url version
  "
  let l:url = l:link.scheme ==# 'wiki' ? l:link.stripped : l:link.url

  "
  " Get replace string
  "
  if l:type ==# 'md'
    if empty(l:link.text)
      let l:parts = split(g:vimwiki.link_matcher.wiki.template[0], '__Url__')
      let l:new = l:parts[0] . l:url . l:parts[1]
    else
      let l:parts = split(g:vimwiki.link_matcher.wiki.template[1],
            \ '__Url__\|__Text__')
      let l:new = l:parts[0] . l:url . l:parts[1] . l:link.text . l:parts[2]
    endif
  elseif l:type ==# 'wiki'
    if empty(l:link.text)
      let l:new = l:url
    else
      let l:parts = split(g:vimwiki.link_matcher.md.template, '__Url__\|__Text__')
      let l:new = l:parts[0] . l:link.text . l:parts[1] . l:url . l:parts[2]
    endif
  elseif l:type ==# 'url'
    let l:parts = split(g:vimwiki.link_matcher.md.template, '__Url__\|__Text__')
    let l:new = l:parts[0] . 'XXX' . l:parts[1] . l:url . l:parts[2]
  endif

  "
  " TODO: Replace current link with l:new
  "
endfunction

" }}}1

function! s:parse_link_wiki(link) " {{{1
  let l:link = {}
  let l:link.follow = function('s:follow_link_wiki')

  " Parse link anchor
  let l:anchors = split(a:link.stripped, '#', 1)
  let l:link.anchor = (len(l:anchors) > 1) && (l:anchors[-1] != '')
        \ ? join(l:anchors[1:], '#') : ''
  let l:link.stripped = !empty(l:anchors[0]) ? l:anchors[0]
        \ : fnamemodify(a:link.origin, ':p:t:r')

  " Extract target filename (full path)
  if a:link.scheme ==# 'diary'
    let l:link.scheme = 'wiki'
    let l:link.filename = g:vimwiki.diary . l:link.stripped . '.wiki'
  else
    if a:link.stripped[0] == '/'
      let l:link.stripped = strpart(l:link.stripped, 1)
      let l:link.filename = g:vimwiki.root . l:link.stripped . '.wiki'
    else
      let l:link.filename = fnamemodify(a:link.origin, ':p:h') . '/'
            \ . l:link.stripped . '.wiki'
    endif
  endif

  return l:link
endfunction

" }}}1
function! s:parse_link_file(link) " {{{1
  if a:link.stripped[0] ==# '/'
    let l:filename = a:link.stripped
  elseif a:link.stripped =~# '\~\w*\/'
    let l:filename = simplify(fnamemodify(a:link.stripped, ':p'))
  else
    let l:filename = simplify(
          \ fnamemodify(a:link.origin, ':p:h') . '/' . a:link.stripped)
  endif

  return { 'follow' : function('s:follow_link_file'),
        \  'filename' : l:filename }
endfunction

" }}}1
function! s:parse_link_doi(link) " {{{1
  return {
        \ 'scheme' : 'http',
        \ 'stripped' : 'dx.doi.org/' . a:link.stripped,
        \ 'url' : 'http://dx.doi.org/' . a:link.stripped,
        \ 'follow' : function('s:follow_link_external'),
        \}
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
"       noautocmd execute 'vimgrep #'
"         \ . g:vimwiki.link_matcher.ref_target.rx_full . '#j %'
"     catch /^Vim\%((\a\+)\)\=:E480/
"     endtry

"     for d in getqflist()
"       let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
"       let descr = matchstr(matchline, g:vimwiki.link_matcher.ref_target.rx_text)
"       let url = matchstr(matchline, g:vimwiki.link_matcher.ref_target.rx_url)
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
function! s:follow_link_external(...) dict " {{{1
  call system('xdg-open ' . shellescape(self.url) . '&')
endfunction

"}}}1

function! s:normalize_helper(str, matcher, template) " {{{1
  let l:url = matchstr(a:str, a:matcher.rx_url)
  let l:text = matchstr(a:str, get(a:matcher, 'rx_text', ''))
  if empty(l:text)
    let l:text = split(l:url, '/\|=\|-\|&\|?\|\.')
    let l:text = filter(l:text, 'v:val !=# ""')
    let l:text = filter(l:text, 'v:val !=# "www"')
    let l:text = filter(l:text, 'v:val !=# "com"')
    let l:text = filter(l:text, 'v:val !=# "org"')
    let l:text = filter(l:text, 'v:val !=# "net"')
    let l:text = filter(l:text, 'v:val !=# "edu"')
    let l:text = filter(l:text, 'v:val !=# "http\:"')
    let l:text = filter(l:text, 'v:val !=# "https\:"')
    let l:text = filter(l:text, 'v:val !=# "file\:"')
    let l:text = filter(l:text, 'v:val !=# "xml\:"')
    let l:text = join(l:text, " ")
  endif

  return substitute(
        \ substitute(a:template, '__Text__', '\="' . l:text . '"', ''),
        \ '__Url__', '\="' . l:url . '"', '')
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
    let template = g:vimwiki.link_matcher.wiki.template[0]
  else
    let depth = len(split(link_diary, '/'))
    let str = repeat('../', depth) . a:lnk . '|' . a:lnk
    let rxUrl = '^.*\ze|'
    let rxDesc = '|\zs.*$'
    let template = g:vimwiki.link_matcher.wiki.template[1]
  endif

  return s:normalize_helper(str,
        \ { 'rx_url' : rxUrl, 'rx_text' : rxDesc },
        \ template)
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
