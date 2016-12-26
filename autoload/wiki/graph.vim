" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#graph#tree_from_current() " {{{1
  call s:graph.init()

  "
  " Define starting point
  "
  let l:current = expand('%:t:r')
  let l:tree = { l:current : l:current }
  let l:stack = map(copy(s:graph.nodes[l:current]), '[v:val, [l:current]]')
  let l:visited = []

  "
  " Generate tree
  "
  while !empty(l:stack)
    let [l:current, l:old_path] = remove(l:stack, 0)
    if index(l:visited, l:current) >= 0 | continue | endif
    let l:visited += [l:current]

    let l:path = l:old_path + [l:current]
    let l:new = map(copy(get(s:graph.nodes, l:current, [])), '[v:val, l:path]')
    let l:stack += l:new

    if !has_key(l:tree, l:current)
      let l:tree[l:current] = join(l:path, ' / ')
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


let s:graph = get(s:, 'graph', {})

function! s:graph.init() dict " {{{1
  if has_key(self, 'initialized') | return | endif
  let self.initialized = 1
  let self.nodes = {}

  let l:files = globpath(g:wiki.root, '**/*.wiki', 0, 1)
  let l:n = len(l:files)
  let l:i = 1
  for l:file in l:files
    let l:node = fnamemodify(l:file, ':t:r')
    echon "\r" . printf("wiki: Scanning (%d/%d): %s", l:i, l:n, l:node)

    let l:targets = filter(wiki#link#get_all(l:file),
          \   'get(v:val, ''scheme'', '''') ==# ''wiki''')
    call uniq(map(l:targets,
          \ 'fnamemodify(get(v:val, ''path'', ''test''), '':t:r'')'))

    let self.nodes[l:node] = l:targets
    let l:i += 1
  endfor
endfunction

" }}}1
