" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#graph#show_link_tree() " {{{1
  call s:graph.init()

  let l:start = expand('%:t:r')
  let l:current = l:start
  let l:tree = { l:current : l:current }
  let l:stack = map(copy(s:graph.nodes[l:current]), '[v:val, [l:current]]')
  let l:visited = []

  while !empty(l:stack)
    let [l:current, l:path] = remove(l:stack, 0)
    if index(l:visited, l:current) >= 0 | continue | endif
    let l:visited += [l:current]

    let l:new_path = l:path + [l:current]
    let l:new = copy(get(s:graph.nodes, l:current, []))
    call map(l:new, '[v:val, l:new_path]')

    if !has_key(l:tree, l:current)
      let l:tree[l:current] = join(l:new_path, ' -> ')
    endif

    let l:stack += l:new
  endwhile

  let l:last = ''
  for l:entry in sort(values(l:tree))
    if match(l:entry, l:last)
      let l:test = repeat(' ', len(l:last))
            \ . substitute(l:entry, '^' . l:last, '', '')
      echom l:test
    else
      echom l:entry
    endif
    let l:last = l:entry
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
