" A wiki plugin for Vim
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
function! wiki#complete#url(lead, line, pos) abort " {{{1
  let l:parts = split(a:lead, '::')
  if len(l:parts) > 1 | return [] | endif

  let l:base = ''
  let l:input = get(l:parts, 0, '')

  let l:cnum = s:completer_wikilink.findstart('[[' . l:input) - 2
  if l:cnum > 0
    let l:base = l:input[:l:cnum-1]
    let l:input = l:input[l:cnum:]
  endif

  let l:candidates = s:completer_wikilink.complete(l:input)
  call map(l:candidates, 'v:val.word')
  if !s:completer_wikilink.is_anchor
    return s:filter_candidates(l:candidates, '^' . l:input)
  endif

  return map(l:candidates, 'l:base . v:val')
endfunction

" }}}1
function! wiki#complete#tag_names(lead, line, pos) abort " {{{1
  return wiki#tags#get_tag_names()
endfunction

" }}}1
function! wiki#complete#graph_export(lead, line, pos) abort " {{{1
  " Complete the value of the options that take one
  for [l:option, l:values] in items(s:graph_export_values)
    if stridx(a:lead, l:option) != 0 | continue | endif

    let l:value = strpart(a:lead, strlen(l:option))
    let l:candidates = type(l:values) == v:t_list
          \ ? copy(l:values)
          \ : getcompletion(l:value, l:values)

    return map(
          \ filter(l:candidates, { _, x -> stridx(x, l:value) == 0 }),
          \ { _, x -> l:option . x })
  endfor

  return filter(copy(s:graph_export_options),
        \ { _, x -> stridx(x, a:lead) == 0 })
endfunction

let s:graph_export_options = [
      \ '--format=',
      \ '--output=',
      \ '--depth=',
      \ '--from',
      \ '--to',
      \ '--both',
      \ '--no-journal',
      \ '--color-distance',
      \ '--open',
      \ '--edit',
      \]

let s:graph_export_values = {
      \ '--format=': ['dot', 'mermaid'],
      \ '--output=': 'file',
      \}

" }}}1
function! wiki#complete#refile(lead, line, pos) abort " {{{1
  " Gather the arguments that are already complete, i.e. all arguments before
  " the one that is currently being typed
  let l:line = strpart(a:line, 0, a:pos)
  let l:args = split(l:line, '\%(\\\)\@<!\s\+')[1:]
  if !empty(l:args) && l:line !~# '\s$'
    call remove(l:args, -1)
  endif

  " Complete the value of the preceding option
  let l:option = empty(l:args) ? '' : l:args[-1]
  if l:option ==# '-relation'
    return s:filter_prefix(['inside', 'before', 'after'], a:lead)
  elseif l:option ==# '-page'
    return wiki#complete#pages(a:lead, a:line, a:pos)
  elseif l:option ==# '-anchor'
    " Anchors may contain spaces, which must be escaped on the command line
    let l:i = index(l:args, '-page')
    let l:page = l:i >= 0 && l:i < len(l:args) - 1
          \ ? substitute(l:args[l:i + 1], '\\\(.\)', '\1', 'g')
          \ : ''
    return s:filter_prefix(
          \ map(wiki#toc#gather_anchors(l:page), { _, x -> escape(x, '\ ') }),
          \ a:lead)
  elseif l:option ==# '-lnum'
    return []
  endif

  " Only complete the options that may still be used
  let l:used = s:refile_used_options(l:args)
  let l:candidates = filter(copy(s:refile_options),
        \ { _, x -> index(l:used, x) < 0 })

  " -lnum can not be combined with -anchor or -relation
  if index(l:used, '-lnum') >= 0
    call filter(l:candidates,
          \ { _, x -> index(['-anchor', '-relation'], x) < 0 })
  elseif index(l:used, '-anchor') >= 0 || index(l:used, '-relation') >= 0
    call filter(l:candidates, { _, x -> x !=# '-lnum' })
  endif

  return s:filter_prefix(l:candidates, a:lead)
endfunction

let s:refile_options = ['-page', '-anchor', '-relation', '-lnum']

function! s:refile_used_options(args) abort
  " Return the options that occur in a:args, skipping over their values

  let l:used = []
  let l:i = 0
  while l:i < len(a:args)
    if index(s:refile_options, a:args[l:i]) >= 0
      call add(l:used, a:args[l:i])
      let l:i += 2
    else
      let l:i += 1
    endif
  endwhile

  return l:used
endfunction

" }}}1
function! wiki#complete#pages(lead, line, pos) abort " {{{1
  return wiki#page#get_all(#{
        \ prefix: substitute(a:lead, '^\/*', '', ''),
        \ only_relative: v:true
        \})
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
  let l:cnum = match(a:line, '\[\[\zs[^\\[\]|]\{-}$')
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
  let l:url = wiki#url#resolve(self.base)
  let l:base = '#' . (empty(l:url.anchor) ? '' : l:url.anchor . '#')
  let l:length = strlen(l:base)

  let l:anchors = wiki#toc#gather_anchors(l:url)
  call s:filter_candidates(
        \ l:anchors,
        \ '^' . escape(l:base, '~.*[]\^$') . '[^#]*$'
        \)
  call map(l:anchors, 'strpart(v:val, l:length)')
  if !empty(a:regex)
    call s:filter_candidates(l:anchors, a:regex)
  endif

  return l:anchors
endfunction

function! s:completer_wikilink.complete_page(regex) dict abort " {{{2
  let l:root = self.rooted ? b:wiki.root : expand('%:p:h')
  let l:pre = self.rooted ? '/' : ''

  if executable('fd')
    let l:extensions = ' -e ' . join(g:wiki_filetypes, ' -e ')
    let l:cands = wiki#jobs#capture(
        \ printf("fd -Ia -t f %s . '%s'", l:extensions, l:root))
  else
    let l:cands = []
    for l:ext in g:wiki_filetypes
      let l:cands += globpath(l:root, '**/*.' . l:ext, 0, 1)
    endfor
  endif

  call map(l:cands, 'strpart(v:val, strlen(l:root)+1)')
  call map(l:cands,
        \ empty(wiki#link#get_creator('url_extension'))
        \ ? 'l:pre . fnamemodify(v:val, '':r'')'
        \ : 'l:pre . v:val')
  call s:filter_candidates(l:cands, a:regex)

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
  " specific regular expression to wiki#toc#gather_anchors().
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
  for l:parser in g:wiki_tag_parsers
    if !has_key(l:parser, 're_findstart') | continue | endif

    let l:col = match(a:line, l:parser.re_findstart)
    if l:col > 0 | return l:col | endif
  endfor

  return -1
endfunction

function! s:completer_tags.complete(regex) dict abort " {{{2
  let l:candidates = keys(wiki#tags#get_all())
  call s:filter_candidates(l:candidates, a:regex)
  return map(sort(l:candidates), {_, x -> {
        \ 'word': x,
        \ 'kind': '[tag]'
        \}})
endfunction

" }}}1

"
" Utility
"
function s:filter_candidates(cands, regex) " {{{1
  " Filter list a:cands for a match with a:regex anywhere in items, with
  " case-sensitivity depending on the value of g:wiki_completion_case_sensitive
  " The list is filtered in place and is also returned.
  return filter(a:cands, {_,x -> match(x,
        \ (g:wiki_completion_case_sensitive ? '\C' : '\c')
        \ . a:regex) >= 0})
endfunction
" }}}1
function s:filter_prefix(cands, lead) " {{{1
  return filter(copy(a:cands), { _, x -> stridx(x, a:lead) == 0 })
endfunction
" }}}1

"
" Initialize module
"
let s:completers = map(
      \ filter(items(s:), 'v:val[0] =~# ''^completer_'''),
      \ 'v:val[1]')

" vim: fdm=marker
