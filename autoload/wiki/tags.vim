" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#tags#get_all() abort " {{{1
  return s:tags.gather()
endfunction

" }}}1
function! wiki#tags#get_tag_names() abort " {{{1
  return keys(wiki#tags#get_all())
endfunction

" }}}1
function! wiki#tags#complete_tag_names(...) abort " {{{1
  " Returns tag names in newline separated string suitable for completion with
  " the "custom" argument, see ":help :command-completion-custom". We could
  " also have used "customlist", but with "custom", filtering is performed
  " implicitly and may be more efficient (cf. documentation).
  return join(map(wiki#tags#get_tag_names(), 'escape(v:val, " ")'), "\n")
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
    let l:cfg.tag = wiki#ui#input(#{info: 'Specify tag:'})
    redraw
  endif

  call s:search(l:cfg)
endfunction

" }}}1
function! wiki#tags#list(...) abort " {{{1
  if empty(s:tags.gather()) | return wiki#log#info('No tags') | endif

  let l:cfg = deepcopy(g:wiki_tag_list)

  let l:args = copy(a:000)
  while !empty(l:args)
    let l:arg = remove(l:args, 0)
    if l:arg ==# '-output'
      let l:cfg.output = remove(l:args, 0)
    else
      return wiki#log#error(
            \ 'WikiTagList argument "' . l:arg . '" not recognized',
            \ 'Please see :help WikiTagList',
            \)
    endif
  endwhile

  try
    call s:list_output_{l:cfg.output}()
  catch /E117:/
    call wiki#log#error(
          \ 'WikiTagList output type "' . l:cfg.output . '" not recognized!',
          \ 'Please see :help WikiTagList'
          \)
  endtry
endfunction

" }}}1
function! wiki#tags#reload() abort " {{{1
  call s:tags.reload()
endfunction

" }}}1
function! wiki#tags#rename(old_tag, ...) abort " {{{1
  let l:new_tag = get(a:000, 0, '')
  let l:rename_to_existing = get(a:000, 1, v:false)

  if l:new_tag ==# ''
    call wiki#tags#rename_ask(a:old_tag)
  else
    call s:tags.rename(a:old_tag, l:new_tag, l:rename_to_existing)
  endif
endfunction

" }}}1
function! wiki#tags#rename_ask(...) abort " {{{1
  let l:old_tag = get(a:000, 0, '')
  let l:new_tag = get(a:000, 1, '')

  " Get old tag name
  if empty(l:old_tag)
    let l:old_tag = wiki#ui#input(#{
          \ info: 'Enter tag to rename (without delimiters):',
          \ completer: 'custom,wiki#tags#get_tag_names'
          \})
  endif
  if empty(l:old_tag) | return | endif

  " Get new tag name
  if empty(l:new_tag)
    let l:new_tag = wiki#ui#input(#{
          \ info: 'Enter new tag name (without tag delimiters):',
          \})
  endif

  if !wiki#ui#confirm(printf('Rename "%s" to "%s"?', l:old_tag, l:new_tag))
    return
  endif

  call wiki#tags#rename(l:old_tag, l:new_tag)
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
    call s:search_output_{a:cfg.output}(a:cfg, l:tags)
  catch /E117:/
    call wiki#log#warn(
          \ 'WikiTagSearch output type "' . l:cfg.output . '" not recognized!',
          \ 'Please see :help WikiTagSearch'
          \)
  endtry
endfunction

" }}}1

function! s:search_output_loclist(cfg, lst) abort " {{{1
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
function! s:search_output_echo(cfg, lst) abort " {{{1
  call wiki#log#info(printf('Pages with tag "%s"', a:cfg.tag))
  for l:file in map(copy(a:lst), 'v:val[0]')
    call wiki#ui#echo(printf('- %s',
          \ fnamemodify(wiki#paths#shorten_relative(l:file), ':r')))
  endfor
endfunction

" }}}1
function! s:search_output_scratch(cfg, lst) abort " {{{1
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
function! s:search_output_cursor(cfg, lst) abort " {{{1
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


function! s:list_output_loclist() abort " {{{1
  let l:list = []
  for [l:tag, l:locations] in items(s:tags.collection)
    for [l:file, l:lnum] in l:locations
      call add(l:list, {
            \ 'filename' : l:file,
            \ 'lnum' : l:lnum,
            \ 'text' : l:tag,
            \})
    endfor
  endfor

  call setloclist(0, [], 'r', {'title': 'WikiTagSearch', 'items': l:list})
  lopen
  wincmd w
endfunction

" }}}1
function! s:list_output_echo() abort " {{{1
  call wiki#log#info('Tagged wiki pages')
  for [l:tag, l:locations] in items(s:tags.collection)
    call wiki#ui#echo(l:tag)
    for l:file in map(copy(l:locations), 'v:val[0]')
      call wiki#ui#echo(printf('- %s',
            \ fnamemodify(wiki#paths#shorten_relative(l:file), ':r')))
    endfor
  endfor
endfunction

" }}}1
function! s:list_output_scratch() abort " {{{1
  let l:scratch = {
        \ 'name': 'WikiTagList',
        \ 'lines': ['# Tagged wiki pages'],
        \}

  for [l:tag, l:locations] in items(s:tags.collection)
    call extend(l:scratch.lines, ['', l:tag])
    for [l:file, l:lnum] in l:locations
      let l:name = fnamemodify(wiki#paths#shorten_relative(l:file), ':r')
      call add(l:scratch.lines, '- ' . wiki#link#wiki#template('/' . l:name, l:name))
    endfor
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
function! s:list_output_cursor() abort " {{{1
  let l:lines = ['# Tagged wiki pages']
  for [l:tag, l:locations] in items(s:tags.collection)
    let l:lines += ['', printf('Tag: %s', l:tag)]
    for [l:file, l:lnum] in l:locations
      let l:name = fnamemodify(wiki#paths#shorten_relative(l:file), ':r')
      call add(l:lines, '- ' . wiki#link#wiki#template('/' . l:name, l:name))
    endfor
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
function! s:tags.rename(old_tag, new_tag, ...) abort dict " {{{1
  let l:rename_to_existing = get(a:000, 0, v:false)

  if !has_key(self.collection, a:old_tag)
    redraw!
    call wiki#log#info('Old tag name "' . a:old_tag . '" not found in cache; reloading tags.')
    call wiki#tags#reload()
    if !has_key(self.collection, a:old_tag)
      return wiki#log#warn('No tag named "' . a:old_tag . '", aborting rename.')
    endif
  endif

  if has_key(self.collection, a:new_tag)
    redraw!
    call wiki#log#warn('Tag "' . a:new_tag . '" already exists!')
    if !l:rename_to_existing && !wiki#ui#confirm('Rename anyway?')
      return
    endif
  endif

  call wiki#log#info('Renaming tag "' . a:old_tag . '" to "' . a:new_tag . '".')

  let l:tagpages = self.collection[a:old_tag]

  let l:bufnr = bufnr('')
  " Get list of open wiki buffers
  let l:bufs =
        \ map(
        \   filter(
        \     filter(range(1, bufnr('$')), 'buflisted(v:val)'),
        \     '!empty(getbufvar(v:val, ''wiki''))'),
        \   'fnamemodify(bufname(v:val), '':p'')')

  " Save other wiki buffers
  for l:bufname in l:bufs
    execute 'buffer' fnameescape(l:bufname)
    update
  endfor

  let l:num_files = 0

  " We already know where the tag is in the file, thanks to the cache
  for [l:file, l:lnum] in l:tagpages
    if s:update_tag_in_wiki(l:file, l:lnum, a:old_tag, a:new_tag)
      call self.add(a:new_tag, l:file, l:lnum)
      call remove(self.collection, a:old_tag)
      let l:num_files += 1
    endif
  endfor

  " Refresh other wiki buffers
  for l:bufname in l:bufs
    execute 'buffer' fnameescape(l:bufname)
    edit
  endfor

  " Refresh tags
  silent call wiki#tags#reload()

  execute 'buffer' l:bufnr

  call wiki#log#info(printf('Renamed tags in %d files', l:num_files))
endfunction

" }}}1
function! s:update_tag_in_wiki(path, lnum, old_tag, new_tag) abort
  call wiki#log#info('Renaming tag in: ' . fnamemodify(a:path, ':t'))
  let l:lines = readfile(a:path)
  let l:tagline = l:lines[a:lnum-1]
  for l:parser in g:wiki_tag_parsers
    if l:parser.match(l:tagline)
      let l:tags = l:parser.parse(l:tagline)
      if index(l:tags, a:new_tag) >= 0
        call filter(l:tags, {_, t -> t !=# a:old_tag})
      else
        call map(l:tags, {_, t -> t ==# a:old_tag ? a:new_tag : t})
      endif
      let l:lines[a:lnum-1] = l:parser.make(l:tags, l:tagline)
      call writefile(l:lines, a:path, 's')
      return 1
    endif
  endfor
  return wiki#log#error("Didn't match tagline " . a:path . ':' . a:lnum . ' with any parser')
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
      \ 're_match': '\v%(^|\s):[^: ]+:',
      \ 're_findstart': '\v%(^|\s)(:\zs[^: ]+)+$',
      \ 're_parse': '\v:\zs[^: ]+\ze:'
      \}

function! g:wiki#tags#default_parser.match(line) dict abort
  return a:line =~# self.re_match
endfunction

function! g:wiki#tags#default_parser.parse(line) dict abort
  let l:tags = []
  let l:tag = matchstr(a:line, self.re_parse, 0)

  while !empty(l:tag)
    call add(l:tags, l:tag)
    let l:tag = matchstr(a:line, self.re_parse, 0, len(l:tags) + 1)
  endwhile

  return l:tags
endfunction

function! g:wiki#tags#default_parser.make(taglist, ...) dict abort
  return empty(a:taglist) ? '' : join(map(a:taglist, '":" . v:val . ":"'))
endfunction

" }}}1
