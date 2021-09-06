" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#tags#get_all() abort " {{{1
  return s:tags.gather()
endfunction

" }}}1
function! wiki#tags#search(...) abort " {{{1
  let l:cfg = deepcopy(g:wiki_tag_search)
  let l:cfg.tag = ''

  let l:args = copy(a:000)
  while !empty(l:args)
    let l:arg = remove(l:args, 0)
    if l:arg ==# '-output'
      let l:cfg.output = remove(l:args, 0)
    elseif empty(l:cfg.tag)
      let l:cfg.tag = l:arg
    else
      return wiki#log#error(
            \ 'WikiTagSeach argument "' . l:arg . '" not recognized',
            \ 'Please see :help WikiTagSearch',
            \)
    endif
  endwhile

  if empty(l:cfg.tag)
    let l:cfg.tag = input('Specify tag: ')
    redraw
  endif

  call s:search(l:cfg)
endfunction

" }}}1
function! wiki#tags#list() abort " {{{1
  let l:tags = s:tags.list()

  if empty(l:tags)
    return wiki#log#info('No tags')
  endif

  call wiki#log#info('List of tags')
  for l:tag in l:tags
    call wiki#log#echo('- ' . l:tag)
  endfor
endfunction

" }}}1
function! wiki#tags#reload() abort " {{{1
  call s:tags.reload()
endfunction

" }}}1


function! s:search(cfg) abort " {{{1
  call s:tags.gather()
  let l:tags = get(s:tags.collection, a:cfg.tag, [])

  if empty(l:tags)
    call wiki#log#info('Tag not found: ' . a:cfg.tag)
    return
  endif

  try
    call s:output_{a:cfg.output}(a:cfg, l:tags)
  catch /E117:/
    call wiki#log#warn(
          \ 'WikiTagSearch output type "' . l:cfg.output . '" not recognized!',
          \ 'Please see :help WikiTagSearch'
          \)
  endtry
endfunction

" }}}1

function! s:output_loclist(cfg, lst) abort " {{{1
  let l:list = []
  for [l:file, l:lnum] in a:lst
    call add(l:list, {
          \ 'filename' : l:file,
          \ 'lnum' : l:lnum,
          \ 'text' : a:cfg.tag,
          \})
  endfor

  call setloclist(0, [], 'r', {'title': 'WikiTagSearch', 'items': l:list})
  lopen
  wincmd w
endfunction

" }}}1
function! s:output_echo(cfg, lst) abort " {{{1
  call wiki#log#info(printf('Pages with tag "%s"', a:cfg.tag))
  for l:file in map(copy(a:lst), 'v:val[0]')
    call wiki#log#echo(printf('- %s',
          \ fnamemodify(wiki#paths#shorten_relative(l:file), ':r')))
  endfor
endfunction

" }}}1
function! s:output_scratch(cfg, lst) abort " {{{1
  let l:scratch = {
        \ 'name': 'WikiTagSearch',
        \ 'lines': [printf('Wiki pages with tag: %s', a:cfg.tag)],
        \}

  for [l:file, l:lnum] in a:lst
    let l:name = fnamemodify(wiki#paths#shorten_relative(l:file), ':r')
    call add(l:scratch.lines, '- ' . wiki#link#wiki#template('/' . l:name, l:name))
  endfor

  function! l:scratch.print_content() abort dict
    for l:line in self.lines
      call append('$', l:line)
    endfor
  endfunction

  function! l:scratch.syntax() abort dict
    set conceallevel=2

    execute 'syntax match wikiLinkWiki'
          \ '/' . wiki#link#wiki#matcher().rx . '/'
          \ 'display contains=@NoSpell,wikiLinkWikiConceal'
    syntax match wikiLinkWikiConceal /\[\[\%(\/\|#\)\?\%([^\\\]]\{-}|\)\?/
          \ contained transparent contains=NONE conceal
    syntax match wikiLinkWikiConceal /\]\]/
          \ contained transparent contains=NONE conceal

    syntax match wikiTagSearchTitle /Wiki pages.*: / nextgroup=wikiTagSearchTag
    syntax match wikiTagSearchTag /.*/ contained

    highlight link wikiTagSearchTitle Title
    highlight link wikiTagSearchTag Directory
  endfunction

  call wiki#scratch#new(l:scratch)
endfunction

" }}}1
function! s:output_cursor(cfg, lst) abort " {{{1
  let l:lines = [printf('Wiki pages with tag: %s', a:cfg.tag)]
  for [l:file, l:lnum] in a:lst
    let l:name = fnamemodify(wiki#paths#shorten_relative(l:file), ':r')
    call add(l:lines, '- ' . wiki#link#wiki#template('/' . l:name, l:name))
  endfor
  call add(l:lines, '')

  for l:line in reverse(l:lines)
    call append(line('.'), l:line)
  endfor
endfunction

" }}}1


let s:tags = {
      \ 'collection' : {},
      \ 'parsed' : 0,
      \}

function! s:tags.list() abort dict " {{{1
  return keys(self.gather())
endfunction

" }}}1
function! s:tags.reload() abort dict " {{{1
  let self.parsed = 0
  let self.collection = {}
  call self.gather()
endfunction

" }}}1
function! s:tags.gather() abort dict " {{{1
  if !self.parsed
    let l:t0 = reltime()
    if !has_key(self, 'cache')
      let self.cache = wiki#cache#open('tags', {
            \ 'default': { 'ftime': -1 },
            \ 'validate': {'opts': [
            \   g:wiki_tag_scan_num_lines,
            \   string(g:wiki_tag_parsers),
            \  ]},
            \})
    endif

    let l:files = filter(
          \ globpath(wiki#get_root(), '**/*.*', 0, 1),
          \ {_, x -> index(g:wiki_filetypes, fnamemodify(x, ':e')) >= 0})
    call map(l:files, {_, x -> self.gather_from_file(x)})

    call self.cache.write()
    let self.parsed = 1

    let l:t1 = reltimefloat(reltime(l:t0))
    call wiki#log#info('Parsed tags (took ' . string(l:t1) . ' seconds)')
  endif

  return self.collection
endfunction

" }}}1
function! s:tags.gather_from_file(file) abort dict " {{{1
  let l:current = self.cache.get(a:file)

  let l:ftime = getftime(a:file)
  if l:ftime > l:current.ftime
    let self.cache.modified = 1
    let l:current.ftime = l:ftime
    let l:current.tags = s:parse_tags_in_file(a:file)
  endif

  for [l:tag, l:lnum] in l:current.tags
    call self.add(l:tag, a:file, l:lnum)
  endfor
endfunction

" }}}1
function! s:tags.add(tag, ...) abort dict " {{{1
  if !has_key(self.collection, a:tag)
    let self.collection[a:tag] = []
  endif

  call add(self.collection[a:tag], a:000)
endfunction

" }}}1

function! s:parse_tags_in_file(file) abort " {{{1
  let l:tags = []
  let l:lnum = 0
  let l:is_code = v:false
  let l:lines = g:wiki_tag_scan_num_lines ==# 'all'
        \ ? readfile(a:file)
        \ : readfile(a:file, 0, g:wiki_tag_scan_num_lines)

  for l:line in l:lines
    let l:lnum += 1

    " Ignore code fenced lines
    if l:is_code
      let l:is_code = l:line !~# '^\s*```\s*$'
      continue
    elseif l:line =~# '^\s*```\w*\s*$'
      let l:is_code = v:true
      continue
    endif

    for l:parser in g:wiki_tag_parsers
      if l:parser.match(l:line)
        for l:tag in l:parser.parse(l:line)
          call add(l:tags, [l:tag, l:lnum])
        endfor
        continue
      endif
    endfor
  endfor

  return tags
endfunction

" }}}1


" {{{1 let g:wiki#tags#default_parser = ...
let g:wiki#tags#default_parser = {
      \ 're_match': '\v%(^|\s):\zs[^: ]+\ze:',
      \ 're_findstart': '\v%(^|\s):\zs[^: ]+$'
      \}

function! g:wiki#tags#default_parser.match(line) dict abort
  return a:line =~# self.re_match
endfunction

function! g:wiki#tags#default_parser.parse(line) dict abort
  let l:tags = []
  let l:tag = matchstr(a:line, self.re_match, 0)

  while !empty(l:tag)
    call add(l:tags, l:tag)
    let l:tag = matchstr(a:line, self.re_match, 0, len(l:tags) + 1)
  endwhile

  return l:tags
endfunction

" }}}1
