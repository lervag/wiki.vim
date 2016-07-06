" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" TODO
" - reference links don't work
"

function! vimwiki#link#get_at_cursor() " {{{1
  for l:m in s:matchers_all
    let l:link = s:matchstr_at_cursor(l:m.rx)
    if !empty(l:link)
      let l:link.text = matchstr(l:link.full, get(l:m, 'rx_text', ''))
      let l:link.type = l:m.type
      let l:link.toggle = function('vimwiki#link#template_' . l:m.toggle)
      return l:m.parser(l:link)
    endif
  endfor

  return {}
endfunction

" }}}1
function! vimwiki#link#open(...) "{{{1
  let l:link = vimwiki#link#get_at_cursor()

  try
    call call(l:link.open, a:000)
  catch
    call vimwiki#link#toggle(l:link)
  endtry
endfunction

" }}}1
function! vimwiki#link#toggle(...) " {{{1
  let l:link = a:0 > 0 ? a:1 : vimwiki#link#get_at_cursor()
  if empty(l:link) | return | endif

  "
  " Use stripped url for wiki links
  "
  let l:url = l:link.scheme ==# 'wiki' ? l:link.stripped : l:link.url

  "
  " Apply link template
  "
  let l:new = l:link.toggle(l:url, l:link.text)

  "
  " Replace current link with l:new
  "
  let l:line = getline(l:link.lnum)
  call setline(l:link.lnum,
        \ strpart(l:line, 0, l:link.c1-1) . l:new . strpart(l:line, l:link.c2))
endfunction

" }}}1
function! vimwiki#link#toggle_visual() " {{{1
  "
  " Note: This function assumes that it is called from visual mode.
  "
  call vimwiki#link#toggle({
        \ 'url' : getreg('*'),
        \ 'text' : '',
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : getpos("'>")[2],
        \ 'toggle' : function('vimwiki#link#template_word'),
        \})
endfunction

" }}}1
function! vimwiki#link#toggle_operator(type, ...) " {{{1
  "
  " Note: This function assumes that it is called as an operator.
  "

  let l:save = @@
  silent execute 'normal! `[v`]y'
  let l:word = substitute(@@, '\s\+$', '', '')
  let l:diff = strlen(@@) - strlen(l:word)
  let @@ = l:save

  call vimwiki#link#toggle({
        \ 'url' : l:word,
        \ 'text' : '',
        \ 'scheme' : '',
        \ 'lnum' : line('.'),
        \ 'c1' : getpos("'<")[2],
        \ 'c2' : getpos("'>")[2] - l:diff,
        \ 'toggle' : function('vimwiki#link#template_word'),
        \})
endfunction

" }}}1

function! s:matchstr_at_cursor(regex) " {{{1
  let l:lnum = line('.')
  let l:c1 = searchpos(a:regex, 'ncb', l:lnum)[1]
  let l:c2 = searchpos(a:regex, 'nce', l:lnum)[1]

  if (l:c1 > 0) && (l:c2 > 0)
    return {
          \ 'full' : strpart(getline('.'), l:c1-1, l:c2-l:c1+1),
          \ 'lnum' : l:lnum,
          \ 'c1' : l:c1,
          \ 'c2' : l:c2,
          \}
  else
    return {}
  endif
endfunction

"}}}1

"
" Templates translate url and possibly text into an appropriate link
"
function! vimwiki#link#template_wiki(url, ...) " {{{1
  let l:text = a:0 > 0 ? a:1 : ''
  return empty(l:text)
        \ ? '[[' . a:url . ']]'
        \ : '[[' . a:url . '|' . l:text . ']]'
endfunction

" }}}1
function! vimwiki#link#template_md(url, ...) " {{{1
  let l:text = a:0 > 0 ? a:1 : ''
  if empty(l:text)
    let l:text = input('Link text: ')
  endif
  return '[' . l:text . '](' . a:url . ')'
endfunction

" }}}1
function! vimwiki#link#template_word(url, ...) " {{{1
  "
  " This template returns a wiki template for the provided word(s). It does
  " a smart search for likely candidates and if there is no unique match, it
  " asks for target link.
  "

  "
  " First try local page
  "
  if filereadable(expand('%:p:h') . '/' . a:url . '.wiki')
    return vimwiki#link#template_wiki(a:url)
  endif

  "
  " Next try at wiki root
  "
  if filereadable(g:vimwiki.root . a:url . '.wiki')
    return vimwiki#link#template_wiki('/' . a:url)
  endif

  "
  " Finally we see if there are completable candidates
  "
  let l:candidates = map(
        \ glob(g:vimwiki.root . a:url . '*.wiki', 0, 1),
        \ 'fnamemodify(v:val, '':t:r'')')

  "
  " Solve trivial cases first
  "
  if len(l:candidates) == 0
    return vimwiki#link#template_wiki('/' . a:url)
  elseif len(l:candidates) == 1
    return vimwiki#link#template_wiki('/' . l:candidates[0], a:url)
  endif

  "
  " Finally we ask for user input to choose desired candidate
  "
  while 1
    redraw
    "
    " The list doesn't show for operator mapping unless I print it as one long
    " string
    "
    let l:echo = ''
    for l:i in range(len(l:candidates))
      let l:echo .= '[' . (l:i + 1) . '] ' . l:candidates[l:i] . "\n"
    endfor
    echo l:echo . '[n] New page at wiki root: ' . a:url
    let l:choice = input('Choice: ')

    if l:choice ==# 'n'
      return vimwiki#link#template_wiki('/' . a:url)
    endif

    try
      let l:cand = l:candidates[l:choice - 1]
      redraw!
      return vimwiki#link#template_wiki('/' . l:cand, a:url)
    catch
      continue
    endtry
  endwhile
endfunction

" }}}1
function! vimwiki#link#template_ref(url, ...) " {{{1
  return vimwiki#link#template_wiki(a:url)
endfunction

" }}}1

"
" Link matchers are the matcher objects used to parse and create links
"
" {{{1 Link matchers

function! vimwiki#link#get_matcher(name) " {{{2
  return s:matcher_{a:name}
endfunction

" }}}2
function! vimwiki#link#get_matcher_opt(name, opt) " {{{2
  return escape(s:matcher_{a:name}[a:opt], '')
endfunction

" }}}2
function! vimwiki#link#get_matchers() " {{{2
  return s:matchers_all
endfunction

" }}}2
function! vimwiki#link#get_matchers_links() " {{{2
  return s:matchers_all_links
endfunction

" }}}2

function! s:parser_general(link) dict " {{{2
  return extend(a:link, vimwiki#url#parse(
        \ matchstr(a:link.full, get(self, 'rx_url', get(self, 'rx')))))
endfunction

" }}}2
function! s:parser_date(link) dict " {{{2
  return extend(a:link, vimwiki#url#parse('diary:' . a:link.full))
endfunction

" }}}2
function! s:parser_word(link) dict " {{{2
  return extend(a:link, {
        \ 'scheme' : '',
        \ 'url' : a:link.full,
        \})
endfunction

" }}}2
function! s:parser_ref(link) dict " {{{2
  return a:link
endfunction

" }}}2

" {{{2 Define the matchers

" Common url regex
let s:rx_url = '\<\l\+:\%(\/\/\)\?[^ \t()\[\]|]\+'

let s:matcher_wiki = {
      \ 'type' : 'wiki',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'md',
      \ 'rx'      : '\[\[\/\?[^\\\]]\{-}\%(|[^\\\]]\{-}\)\?\]\]',
      \ 'rx_url'  : '\[\[\zs\/\?[^\\\]]\{-}\ze\%(|[^\\\]]\{-}\)\?\]\]',
      \ 'rx_text' : '\[\[\/\?[^\\\]]\{-}|\zs[^\\\]]\{-}\ze\]\]',
      \}

let s:matcher_md = {
      \ 'type' : 'md',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'wiki',
      \ 'rx'      : '\[[^\\]\{-}\]([^\\]\{-})',
      \ 'rx_url'  : '\[[^\\]\{-}\](\zs[^\\]\{-}\ze)',
      \ 'rx_text' : '\[\zs[^\\]\{-}\ze\]([^\\]\{-})',
      \}

let s:matcher_ref = {
      \ 'type' : 'ref',
      \ 'parser' : function('s:parser_ref'),
      \ 'toggle' : 'ref',
      \ 'rx' : '[\]\[]\@<!\['
      \   . '[^\\\[\]]\{-}\]\[\%([^\\\[\]]\{-}\)\?'
      \   . '\][\]\[]\@!',
      \ 'rx_url' : '[\]\[]\@<!\['
      \   . '\%(\zs[^\\\[\]]\{-}\ze\]\[\|[^\\\[\]]\{-}\]\[\zs[^\\\[\]]\{-1,}\ze\)'
      \   . '\][\]\[]\@!',
      \ 'rx_text' : '[\]\[]\@<!\['
      \   . '\zs[^\\\[\]]\{-}\ze\]\[[^\\\[\]]\{-1,}'
      \   . '\][\]\[]\@!',
      \}

let s:matcher_ref_simple = {
      \ 'type' : 'ref',
      \ 'parser' : function('s:parser_ref'),
      \ 'toggle' : 'ref',
      \ 'rx' : '[\]\[]\@<!\[[^\\\[\]]\{-}\][\]\[]\@!',
      \ 'rx_url' : '\[\zs[^\\\[\]]\{-}\ze\]',
      \}

let s:matcher_ref_target = {
      \ 'type' : 'ref_target',
      \ 'rx' : '\[[^\\\]]\{-}\]:\s\+' . s:rx_url,
      \ 'rx_url' : '\[[^\\\]]\{-}\]:\s\+\zs' . s:rx_url . '\ze',
      \ 'rx_text' : '\[\zs[^\\\]]\{-}\ze\]:\s\+' . s:rx_url,
      \}

let s:matcher_url = {
      \ 'type' : 'url',
      \ 'parser' : function('s:parser_general'),
      \ 'toggle' : 'md',
      \ 'rx'     : s:rx_url,
      \}

let s:matcher_date = {
      \ 'type' : 'date',
      \ 'parser' : function('s:parser_date'),
      \ 'toggle' : 'wiki',
      \ 'rx' : '\d\d\d\d-\d\d-\d\d',
      \}

let s:matcher_word = {
      \ 'type' : 'word',
      \ 'parser' : function('s:parser_word'),
      \ 'toggle' : 'word',
      \ 'rx' : '\<\w\+\>',
      \}

let s:matchers_all = [
      \ s:matcher_wiki,
      \ s:matcher_md,
      \ s:matcher_ref,
      \ s:matcher_ref_target,
      \ s:matcher_ref_simple,
      \ s:matcher_url,
      \ s:matcher_date,
      \ s:matcher_word,
      \]

let s:matchers_all_links = s:matchers_all[0:-2]

unlet s:rx_url

" }}}2

" }}}1

"
" Old code for opening ref type links
"
function! s:url_open_ref_tmp(...) dict " {{{1
"   if !has_key(b:vimwiki, 'reflinks')
"     let b:vimwiki.reflinks = {}

"     try
"       " Why noautocmd? Because https://github.com/vimwiki/vimwiki/issues/121
"       noautocmd execute 'vimgrep #'
"         \ . g:vimwiki.link_matchers.ref_target.rx . '#j %'
"     catch /^Vim\%((\a\+)\)\=:E480/
"     endtry

"     for d in getqflist()
"       let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
"       let descr = matchstr(matchline, g:vimwiki.link_matchers.ref_target.rx_text)
"       let url = matchstr(matchline, g:vimwiki.link_matchers.ref_target.rx_url)
"       if descr != '' && url != ''
"         let b:vimwiki.reflinks[descr] = url
"       endif
"     endfor
"   endif

"   if has_key(b:vimwiki.reflinks, self.url)
"     call s:url_open_external(b:vimwiki.reflinks[self.url])
"   endif
endfunction

"}}}1

" vim: fdm=marker sw=2
