" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#complete#omnicomplete(findstart, base) abort " {{{1
  if a:findstart
    return wiki#complete#findstart(getline('.')[:col('.') - 2])
  else
    return wiki#complete#complete(a:base)
  endif
endfunction

" }}}1
function! wiki#complete#link(lead, line, pos) abort " {{{1
  let l:parts = split(a:lead, '::')
  if empty(l:parts) || len(l:parts) > 1 | return [] | endif

  let l:base = ''
  let l:input = l:parts[0]

  let l:cnum = s:completer_wikilink.findstart('[[' . l:input) - 2
  if l:cnum > 0
    let l:base = l:input[:l:cnum-1]
    let l:input = l:input[l:cnum:]
  endif

  let l:candidates = s:completer_wikilink.complete(l:input)
  call map(l:candidates, 'v:val.word')
  if !s:completer_wikilink.is_anchor
    return filter(l:candidates, 'stridx(v:val, l:input) == 0')
  endif

  return map(l:candidates, 'l:base . v:val')
endfunction

" }}}1

function! wiki#complete#findstart(line) abort " {{{1
  if exists('s:completer') | unlet s:completer | endif

  for l:completer in s:completers
    let l:cnum = l:completer.findstart(a:line)
    if l:cnum >= 0
      let s:completer = l:completer
      return l:cnum
    endif
  endfor

  " -2  cancel silently and stay in completion mode.
  " -3  cancel silently and leave completion mode.
  return -3
endfunction

" }}}1
function! wiki#complete#complete(input) abort " {{{1
  if !exists('s:completer') | return [] | endif
  return s:completer.complete(a:input)
endfunction

" }}}1

"
" Completers
"
" {{{1 WikiLink

let s:completer_wikilink = {
      \ 'is_anchor': 0,
      \ 'rooted': 0,
      \}

function! s:completer_wikilink.findstart(line) dict abort " {{{2
  let l:cnum = match(a:line, '\[\[\zs[^\\[\]]\{-}$')
  if l:cnum < 0 | return -1 | endif

  let l:base = a:line[l:cnum:]

  let self.rooted = l:base[0] ==# '/'
  let self.is_anchor = l:base =~# '#'
  if !self.is_anchor | return l:cnum | endif

  let self.base = substitute(l:base, '\(.*#\).*', '\1', '')
  return l:cnum + strlen(self.base)
endfunction

function! s:completer_wikilink.complete(regex) dict abort " {{{2
  let l:candidates = self.is_anchor
        \ ? self.complete_anchor(a:regex)
        \ : self.complete_page(a:regex)

  return map(l:candidates, "{'word': v:val, 'menu': '[wiki]'}")
endfunction

function! s:completer_wikilink.complete_anchor(regex) dict abort " {{{2
  let l:url = wiki#url#parse(self.base)
  let l:base = '#' . (empty(l:url.anchor) ? '' : l:url.anchor . '#')
  let l:length = strlen(l:base)

  let l:anchors = wiki#page#get_anchors(l:url)
  call filter(l:anchors, 'v:val =~# ''^'' . wiki#u#escape(l:base) . ''[^#]*$''')
  call map(l:anchors, 'strpart(v:val, l:length)')
  if !empty(a:regex)
    call filter(l:anchors, 'v:val =~# ''' . a:regex . '''')
  endif

  return l:anchors
endfunction

function! s:completer_wikilink.complete_page(regex) dict abort " {{{2
  let l:root = self.rooted ? b:wiki.root : expand('%:p:h')
  let l:pre = self.rooted ? '/' : ''

  let l:cands = executable('fd')
        \ ? systemlist('fd -a -t f -e ' . b:wiki.extension . ' . ' . l:root)
        \ : globpath(l:root, '**/*.' . b:wiki.extension, 0, 1)

  call map(l:cands, 'strpart(v:val, strlen(l:root)+1)')
  call map(l:cands,
        \ empty(b:wiki.link_extension)
        \ ? 'l:pre . fnamemodify(v:val, '':r'')'
        \ : 'l:pre . v:val')
  call filter(l:cands, 'stridx(v:val, a:regex) >= 0')

  call sort(l:cands)

  return l:cands
endfunction

" }}}1
" {{{1 MdLink

let s:completer_mdlink = deepcopy(s:completer_wikilink)

function! s:completer_mdlink.findstart(line) dict abort " {{{2
  let l:cnum = match(a:line, '\](\zs[^)]\{-}$')
  if l:cnum < 0 | return -1 | endif

  let l:base = a:line[l:cnum:]

  let self.rooted = l:base[0] ==# '/'
  let self.is_anchor = l:base =~# '#'
  if !self.is_anchor | return l:cnum | endif

  let self.base = substitute(l:base, '\(.*#\).*', '\1', '')
  return l:cnum + strlen(self.base)
endfunction

" }}}1
" {{{1 AdocBracketLink

let s:completer_adocbracketlink = deepcopy(s:completer_wikilink)

function! s:completer_adocbracketlink.findstart(line) dict abort " {{{2
  let l:cnum = match(a:line, '<<\zs[^,]\{-}$')
  if l:cnum < 0 | return -1 | endif

  let l:base = a:line[l:cnum:]

  let self.rooted = l:base[0] ==# '/'

  " Completion of anchors is disabled because they won't be found for asciidoc
  " anyway: wiki#rx#header_items regex is used for search of anchors and it
  " requires Markdown-style headers. This could be resolved by passing a
  " specific regular expression to wiki#page#get_anchors().
  let self.is_anchor = 0

  return l:cnum
endfunction

" }}}1
" {{{1 Zotero

let s:completer_zotero = {}

function! s:completer_zotero.findstart(line) dict abort " {{{2
  return match(a:line, '\%(zot:\|\%(\s\|^\|\[\)@\)\zs\S*$')
endfunction

function! s:completer_zotero.complete(regex) dict abort " {{{2
  let l:cands = map(wiki#zotero#search(a:regex), 'fnamemodify(v:val, '':t'')')

  return map(sort(l:cands), "{
        \ 'word': split(v:val)[0],
        \ 'menu': join(split(v:val)[2:]),
        \ 'kind': '[z]'
        \}")
endfunction

" }}}1
" {{{1 Tags

let s:completer_tags = {}

function! s:completer_tags.findstart(line) dict abort " {{{2
  for l:parser in g:wiki_tags_parsers
    if !has_key(l:parser, 're_findstart') | continue | endif

    let l:col = match(a:line, l:parser.re_findstart)
    if l:col > 0 | return l:col | endif
  endfor

  return -1
endfunction

function! s:completer_tags.complete(regex) dict abort " {{{2
  let l:candidates = keys(wiki#tags#get_all())
  call filter(l:candidates, {_, x -> stridx(x, a:regex) >= 0})
  return map(sort(l:candidates), {_, x -> {
        \ 'word': x,
        \ 'kind': '[tag]'
        \}})
endfunction

" }}}1

"
" Initialize module
"
let s:completers = map(
      \ filter(items(s:), 'v:val[0] =~# ''^completer_'''),
      \ 'v:val[1]')
