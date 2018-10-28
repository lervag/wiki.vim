" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#graph#find_backlinks() abort "{{{1
  call s:graph.init()

  let l:origin = resolve(expand('%:p'))
  let l:results = []
  for l:content in deepcopy(values(s:graph.nodes))
    let l:results += filter(l:content.links, 'v:val.target ==# l:origin')
  endfor

  for l:link in l:results
    let l:link.text =
          \ (!empty(l:link.anchor) ? '[' . l:link.anchor . '] ' : '')
          \ . l:link.text
  endfor

  if empty(l:results)
    echomsg 'wiki: No other file links to this file'
  else
    call setloclist(0, l:results, 'r')
    lopen
  endif
endfunction

"}}}1

function! wiki#graph#from_current() abort " {{{1
  call s:graph.init()

  "
  " Define starting point
  "
  let l:stack = [[expand('%:t:r'), []]]
  let l:tree = {}
  let l:visited = []

  "
  " Generate tree
  "
  while !empty(l:stack)
    let [l:node, l:path] = remove(l:stack, 0)
    if index(l:visited, l:node) >= 0 | continue | endif
    let l:visited += [l:node]

    let l:targets = uniq(map(s:graph.get_links_from(l:node),
          \ 'fnamemodify(v:val.target, '':t:r'')'))
    let l:new_path = l:path + [l:node]
    let l:stack += map(l:targets, '[v:val, l:new_path]')

    if !has_key(l:tree, l:node)
      let l:tree[l:node] = join(l:new_path, ' / ')
    endif
  endwhile

  "
  " Print the tree
  "
  for l:entry in sort(values(l:tree))
    echom l:entry
  endfor
endfunction

" }}}1
function! wiki#graph#to_current() abort "{{{1
  call s:graph.init()

  let l:stack = [[expand('%:t:r'), []]]
  let l:visited = []
  let l:tree = {}

  while !empty(l:stack)
    let [l:node, l:path] = remove(l:stack, 0)
    if index(l:visited, l:node) >= 0 | continue | endif
    let l:visited += [l:node]

    let l:new_path = l:path + [l:node]
    let l:stack += map(filter(keys(s:graph.nodes),
          \   's:graph.has_link(v:val, l:node)'),
          \ '[v:val, l:new_path]')

    if !has_key(l:tree, l:node)
      let l:tree[l:node] = join(l:new_path, ' / ')
    endif
  endwhile

  "
  " Print the tree
  "
  for l:entry in sort(values(l:tree))
    echom l:entry
  endfor
endfunction

"}}}1


let s:graph = get(s:, 'graph', {})

function! s:graph.init() abort dict " {{{1
  if has_key(self, 'initialized') | return | endif
  let self.nodes = {}

  echohl ModeMsg
  echo 'wiki: Scanning graph ... '
  echohl NONE
  let l:files = globpath(b:wiki.root, '**/*.' . b:wiki.extension, 0, 1)
  let l:n = len(l:files)
  let l:i = 1
  for l:file in l:files
    let l:node = fnamemodify(l:file, ':t:r')

    if has_key(self.nodes, l:node)
      echoerr 'Not implemented!'
    endif

    let self.nodes[l:node] = {
          \ 'path' : resolve(l:file),
          \ 'links' : [],
          \}

    for l:link in filter(wiki#link#get_all(l:file),
          \ 'get(v:val, ''scheme'', '''') ==# ''wiki''')
      call add(self.nodes[l:node].links, {
            \ 'text' : get(l:link, 'text'),
            \ 'target' : resolve(l:link.path),
            \ 'anchor' : l:link.anchor,
            \ 'filename' : l:file,
            \ 'lnum' : l:link.lnum,
            \ 'col' : l:link.c1
            \})
     endfor

    let l:i += 1
  endfor
  echohl ModeMSG
  echon 'DONE'
  echohl NONE
  sleep 100m

  let self.initialized = 1
endfunction

" }}}1
function! s:graph.has_link(from, to) abort dict " {{{1
  let l:target = get(get(self.nodes, a:to, {}), 'path')
  let l:links = get(get(self.nodes, a:from, {}), 'links', [])

  for l:link in l:links
    if l:link.target ==# l:target | return 1 | endif
  endfor

  return 0
endfunction

" }}}1
function! s:graph.get_links_from(node) abort dict " {{{1
  return deepcopy(get(get(self.nodes, a:node, {}), 'links', []))
endfunction

" }}}1
