" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#tags#search(...) abort " {{{1
  let l:cfg = deepcopy(g:wiki_tags)
  let l:cfg.tag = ''

  let l:args = copy(a:000)
  while !empty(l:args)
    let l:arg = remove(l:args, 0)
    if l:arg ==# '-output'
      let l:cfg.output = remove(l:args, 0)
    elseif empty(l:cfg.tag)
      let l:cfg.tag = l:arg
    else
      echomsg 'WikiTagSeach: Argument "' . l:arg . '" not recognized'
      echomsg '              Please see :help WikiTagSearch'
      return
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
    echo 'wiki.vim: No tags'
    return
  endif

  echo 'Tags:'
  for l:tag in l:tags
    echo '-' l:tag
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
    echo 'wiki.vim: Tag not found:' a:cfg.tag
    return
  endif

  try
    call s:output_{a:cfg.output}(a:cfg, l:tags)
  catch /E117/
    echomsg 'WikiTagSeach: Output type "' . l:cfg.output . '" not recognized!'
    echomsg '              Please see :help WikiTagSearch'
  endtry
endfunction

" }}}1

function! s:output_loclist(cfg, lst) abort " {{{1
  let l:list = []
  for [l:file, l:lnum, l:col] in a:lst
    call add(l:list, {
          \ 'filename' : l:file,
          \ 'lnum' : l:lnum,
          \ 'col' : l:col,
          \ 'text' : a:cfg.tag,
          \})
  endfor

  call setloclist(0, [], 'r', {'title': 'WikiTagSearch', 'items': l:list})
  lopen
  wincmd w
endfunction

" }}}1
function! s:output_echo(cfg, lst) abort " {{{1
  echom printf('wiki.vim: Pages with tag "%s"', a:cfg.tag)
  for l:file in map(copy(a:lst), 'v:val[0]')
    echom printf('- %s',
          \ fnamemodify(wiki#paths#shorten_relative(l:file), ':r'))
  endfor
endfunction

" }}}1
function! s:output_scratch(cfg, lst) abort " {{{1
  let l:scratch = {
        \ 'name': 'WikiTagSearch',
        \ 'lines': [printf('Wiki pages with tag: %s', a:cfg.tag)],
        \}

  for [l:file, l:lnum, l:col] in a:lst
    call add(l:scratch.lines, '- ' . wiki#link#template_wiki('/' .
          \ fnamemodify(wiki#paths#shorten_relative(l:file), ':r')))
  endfor

  function! l:scratch.print_content() abort dict
    for l:line in self.lines
      call append('$', l:line)
    endfor
  endfunction

  function! l:scratch.syntax() abort dict
    set conceallevel=2

    execute 'syntax match wikiLinkWiki'
          \ '/' . wiki#link#get_matcher_opt('wiki', 'rx') . '/'
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
  for [l:file, l:lnum, l:col] in a:lst
    call add(l:lines, '- ' . wiki#link#template_wiki('/' .
          \ fnamemodify(wiki#paths#shorten_relative(l:file), ':r')))
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
  let l:parsed = 0
  call self.gather()
endfunction

" }}}1
function! s:tags.gather() abort dict " {{{1
  if !self.parsed
    for l:file in globpath(b:wiki.root, '**/*.' . b:wiki.extension, 0, 1)
      call self.gather_from_file(l:file)
    endfor
    let self.parsed = 1
  endif

  return self.collection
endfunction

" }}}1
function! s:tags.gather_from_file(file) abort dict " {{{1
  let l:lnum = 0
  let l:is_code = 0
  for l:line in readfile(a:file, 0, 15)
    let l:lnum += 1
    let l:col = 0

    " Ignore code fenced lines
    if l:is_code
      let l:is_code = l:line !~# '^\s*```\s*$'
      continue
    elseif l:line =~# '^\s*```\w*\s*$'
      let l:is_code = 1
      continue
    endif

    while v:true
      let [l:tag, l:pos, l:col]
            \ = matchstrpos(l:line, '\v%(^|\s):\zs[^: ]+\ze:', l:col)
      if l:col == -1 | break | endif

      call self.add(l:tag, a:file, l:lnum, l:pos)
    endwhile
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
