" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#graph#find_backlinks() abort "{{{1
  if !has_key(b:wiki, 'graph')
    let b:wiki.graph = s:graph.init()
  endif

  let l:origin = s:file_to_node(expand('%:p'))
  let l:results = b:wiki.graph.links_to(l:origin)

  for l:link in l:results
    let l:link.filename = l:link.filename_from
    let l:link.text = readfile(l:link.filename, 0, l:link.lnum)[-1]
  endfor

  if empty(l:results)
    call wiki#log#info('wiki: No other file links to this file')
  else
    call setloclist(0, l:results, 'r')
    lopen
  endif
endfunction

"}}}1

function! wiki#graph#out(...) abort " {{{1
  let l:max_level = a:0 > 0 ? a:1 : -1

  if !has_key(b:wiki, 'graph')
    let b:wiki.graph = s:graph.init()
  endif

  let l:stack = [[s:file_to_node(expand('%:p')), []]]
  let l:visited = []
  let l:tree = {}

  "
  " Generate tree
  "
  while !empty(l:stack)
    let [l:node, l:path] = remove(l:stack, 0)
    if index(l:visited, l:node) >= 0 | continue | endif
    let l:visited += [l:node]

    let l:current_path = l:path + [l:node]
    if l:max_level > 0 && len(l:current_path) > l:max_level + 1
      continue
    endif

    let l:stack += map(b:wiki.graph.links_from(l:node),
          \ '[v:val.node_to, l:current_path]')

    if !has_key(l:tree, l:node)
      let l:tree[l:node] = join(l:current_path, ' / ')
    endif
  endwhile

  "
  " Show graph in scratch buffer
  "
  call s:output_to_scratch('WikiGraphOut', sort(values(l:tree)))
endfunction

" }}}1
function! wiki#graph#in(...) abort "{{{1
  let l:max_level = a:0 > 0 ? a:1 : -1

  if !has_key(b:wiki, 'graph')
    let b:wiki.graph = s:graph.init()
  endif

  let l:stack = [[s:file_to_node(expand('%:p')), []]]
  let l:visited = []
  let l:tree = {}

  "
  " Generate tree
  "
  while !empty(l:stack)
    let [l:node, l:path] = remove(l:stack, 0)
    if index(l:visited, l:node) >= 0 | continue | endif
    let l:visited += [l:node]

    let l:current_path = l:path + [l:node]
    if l:max_level > 0 && len(l:current_path) > l:max_level + 1
      continue
    endif

    let l:links = b:wiki.graph.links_to(l:node)
    let l:stack += map(l:links,
          \ '[v:val.node_from, l:current_path]')

    if !has_key(l:tree, l:node)
      let l:tree[l:node] = join(l:current_path, ' / ')
    endif
  endwhile

  "
  " Show graph in scratch buffer
  "
  call s:output_to_scratch('WikiGraphIn', sort(values(l:tree)))
endfunction

"}}}1


let s:graph = {}

function! s:graph.init() abort dict " {{{1
  let new = deepcopy(s:graph)
  unlet new.init

  let new.nodes = s:gather_nodes()

  return new
endfunction

" }}}1
function! s:graph.links_from(node) abort dict " {{{1
  return deepcopy(get(get(self.nodes, a:node, {}), 'links', []))
endfunction

" }}}1
function! s:graph.links_to(node) abort dict " {{{1
  return deepcopy(get(get(self.nodes, a:node, {}), 'linked', []))
endfunction

" }}}1

function! s:gather_nodes() abort " {{{1
  if has_key(s:nodes, b:wiki.root)
    return s:nodes[b:wiki.root]
  endif

  redraw
  call wiki#log#info('Scanning wiki graph nodes ... ')
  sleep 25m

  let l:cache = wiki#cache#open('graph', {
        \ 'local': 1,
        \ 'default': { 'ftime': -1 },
        \})

  let l:gathered = {}
  for l:file in globpath(b:wiki.root, '**/*.' . b:wiki.extension, 0, 1)
    let l:node = s:file_to_node(l:file)

    let l:current = l:cache.get(l:file)
    let l:ftime = getftime(l:file)
    if l:ftime > l:current.ftime
      let l:cache.modified = 1
      let l:current.ftime = l:ftime
      let l:current.links = []
      for l:link in filter(wiki#link#get_all(l:file),
            \ 'get(v:val, ''scheme'', '''') ==# ''wiki''')
        call add(l:current.links, {
              \ 'node_from' : l:node,
              \ 'node_to' : s:file_to_node(l:link.path),
              \ 'filename_from' : l:file,
              \ 'filename_to' : resolve(l:link.path),
              \ 'text' : get(l:link, 'text'),
              \ 'anchor' : l:link.anchor,
              \ 'lnum' : l:link.lnum,
              \ 'col' : l:link.c1
              \})
      endfor
    endif

    if has_key(l:gathered, l:node)
      return wiki#log#error('Not implemented!')
    endif

    let l:gathered[l:node] = l:current
  endfor

  " Save cache
  call l:cache.write()

  for l:node in values(l:gathered)
    let l:node.linked = []
  endfor

  for l:node in values(l:gathered)
    for l:link in l:node.links
      if has_key(l:gathered, l:link.node_to)
        call add(l:gathered[l:link.node_to].linked, l:link)
      endif
    endfor
  endfor

  call wiki#log#info('done!')

  let s:nodes[b:wiki.root] = l:gathered
  return l:gathered
endfunction

let s:nodes = {}

" }}}1
function! s:file_to_node(file) abort " {{{1
  return fnamemodify(a:file, ':t:r')
endfunction

" }}}1

"
" Utility functions
"
function! s:output_to_scratch(name, lines) abort " {{{1
  let l:scratch = {
        \ 'name': a:name,
        \ 'lines': a:lines,
        \}

  function! l:scratch.print_content() abort dict
    for l:line in self.lines
      call append('$', l:line)
    endfor
  endfunction

  function! l:scratch.syntax() abort dict
    syntax match ScratchSeparator /\//
    highlight link ScratchSeparator Title
  endfunction

  call wiki#scratch#new(l:scratch)
endfunction

" }}}1
