" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#graph#builder#get() abort " {{{1
  let l:root = wiki#get_root()
  let l:extension = exists('b:wiki.extension')
        \ ? b:wiki.extension
        \ : g:wiki_filetypes[0]

  if !has_key(s:graphs, l:root)
    let s:graphs[l:root] = s:graph.create(l:root, l:extension)
  endif

  return s:graphs[l:root]
endfunction

let s:graphs = {}

" }}}1


let s:graph = {
      \ 'save_cache': v:true,
      \}

function! s:graph.create(root, extension) abort dict " {{{1
  let l:new = deepcopy(s:graph)
  unlet l:new.create

  let l:new.root = a:root
  let l:new.extension = a:extension
  let l:new.cache = wiki#cache#open('graph', {
        \ 'local': 1,
        \ 'default': { 'ftime': -1 },
        \})

  return l:new
endfunction

" }}}1

function! s:graph.get_links_from(file) abort dict " {{{1
  let l:current = self.cache.get(a:file)

  let l:ftime = getftime(a:file)
  if l:ftime > l:current.ftime
    let l:current.ftime = l:ftime
    let l:current.links = map(
          \ filter(
          \   wiki#link#get_all(a:file),
          \   { _, x -> get(x, 'scheme', '') ==# 'wiki'
          \               && a:file !=# resolve(x.path) }),
          \ { _, x -> {
          \   'filename_from' : a:file,
          \   'filename_to' : resolve(x.path),
          \   'content' : x.content,
          \   'text' : get(x, 'text'),
          \   'anchor' : x.anchor,
          \   'lnum' : x.pos_start[0],
          \   'col' : x.pos_start[1]
          \ }
          \})

    let self.cache.modified = 1
    if self.save_cache
      call self.cache.write()
    endif
  endif

  return deepcopy(l:current.links)
endfunction

" }}}1
function! s:graph.get_links_to(file) abort dict " {{{1
  let l:links = []

  let self.save_cache = v:false
  for l:file in globpath(self.root, '**/*.' . self.extension, 0, 1)
    call extend(l:links, filter(
          \ self.get_links_from(l:file),
          \ { _, x -> x.filename_to ==# a:file }
          \))
  endfor
  let self.save_cache = v:true
  call self.cache.write()

  return l:links
endfunction

" }}}1
function! s:graph.get_links_map() abort dict " {{{1
  let l:map = {}

  let self.save_cache = v:false
  for l:file in globpath(self.root, '**/*.' . self.extension, 0, 1)
    let l:map[l:file] = {
          \ 'out': self.get_links_from(l:file),
          \ 'in': []
          \}
  endfor
  let self.save_cache = v:true
  call self.cache.write()

  for l:file in values(l:map)
    for l:link in l:file.out
      if has_key(l:map, l:link.filename_to)
        call add(l:map[l:link.filename_to].in, l:link)
      endif
    endfor
  endfor

  return l:map
endfunction

" }}}1

function! s:graph.get_broken_links_from(file) abort dict " {{{1
  return filter(
        \ self.get_links_from(a:file),
        \ { _, x -> !filereadable(x.filename_to) }
        \)
endfunction

" }}}1
function! s:graph.get_broken_links_global() abort dict " {{{1
  let l:broken_links = []

  let self.save_cache = v:false
  for l:file in globpath(self.root, '**/*.' . self.extension, 0, 1)
    call extend(l:broken_links, self.get_broken_links_from(l:file))
  endfor
  let self.save_cache = v:true
  call self.cache.write()

  return l:broken_links
endfunction

" }}}1

function! s:graph.get_tree_to(file, depth) abort " {{{1
  let l:tree = {}
  let l:stack = [[a:file, []]]
  let l:visited = []

  let l:map = self.get_links_map()

  while !empty(l:stack)
    let [l:file, l:path] = remove(l:stack, 0)
    if index(l:visited, l:file) >= 0 | continue | endif
    let l:visited += [l:file]

    let l:current_path = l:path + [wiki#paths#to_node(l:file)]
    if a:depth > 0 && len(l:current_path) > a:depth + 1
      continue
    endif

    let l:stack += map(
          \ l:map[l:file].in,
          \ { _, x -> [x.filename_from, l:current_path] }
          \)

    if !has_key(l:tree, l:file)
      let l:tree[l:file] = join(l:current_path, ' → ')
    endif
  endwhile

  return l:tree
endfunction

" }}}1
function! s:graph.get_tree_from(file, depth) abort " {{{1
  let l:tree = {}
  let l:stack = [[a:file, []]]
  let l:visited = []

  while !empty(l:stack)
    let [l:file, l:path] = remove(l:stack, 0)
    if index(l:visited, l:file) >= 0 | continue | endif
    let l:visited += [l:file]

    let l:current_path = l:path + [wiki#paths#to_node(l:file)]
    if a:depth > 0 && len(l:current_path) > a:depth + 1
      continue
    endif

    let l:stack += map(
          \ self.get_links_from(l:file),
          \ { _, x -> [x.filename_to, l:current_path] }
          \)

    if !has_key(l:tree, l:file)
      let l:tree[l:file] = join(l:current_path, ' → ')
    endif
  endwhile

  return l:tree
endfunction

" }}}1
