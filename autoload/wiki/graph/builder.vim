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
      \ 'map': {},
      \ 'map_update_freq': 360,
      \ 'map_update_time': -1,
      \ 'save_cache': v:true,
      \}

function! s:graph.create(root, extension) abort dict " {{{1
  let l:new = deepcopy(s:graph)
  unlet l:new.create

  let l:new.root = a:root
  let l:new.extension = a:extension
  let l:new.cache = wiki#cache#open('graph', {
        \ 'local': 1,
        \ 'default': { 'ftime': -1, 'links': [] },
        \})

  return l:new
endfunction

" }}}1

function! s:graph.get_files() abort dict " {{{1
  return globpath(self.root, '**/*.' . self.extension, 0, 1)
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
function! s:graph.get_links_to(file, ...) abort dict " {{{1
  let l:update = a:0 > 0 ? v:true : v:false
  let l:map = self.get_map(l:update)

  return get(get(l:map, a:file, {}), 'in', [])
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
  for l:file in self.get_files()
    call extend(l:broken_links, self.get_broken_links_from(l:file))
  endfor
  let self.save_cache = v:true
  call self.cache.write()

  return l:broken_links
endfunction

" }}}1

function! s:graph.get_tree_to(file, depth, ...) abort " {{{1
  let l:tree = {}
  let l:stack = [[a:file, []]]
  let l:visited = []

  let l:update = a:0 > 0 ? v:true : v:false
  let l:map = self.get_map(l:update)

  while !empty(l:stack)
    let [l:file, l:path] = remove(l:stack, 0)
    if index(l:visited, l:file) >= 0 | continue | endif
    let l:visited += [l:file]

    let l:current_path = l:path + [wiki#paths#to_node(l:file)]
    if a:depth > 0 && len(l:current_path) > a:depth + 1
      continue
    endif

    let l:stack += uniq(map(
          \ l:map[l:file].in,
          \ { _, x -> [x.filename_from, l:current_path] }
          \))

    if !has_key(l:tree, l:file)
      let l:tree[l:file] = join(l:current_path, ' ← ')
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

    let l:stack += uniq(map(
          \ self.get_links_from(l:file),
          \ { _, x -> [x.filename_to, l:current_path] }
          \))

    if !has_key(l:tree, l:file)
      let l:tree[l:file] = join(l:current_path, ' → ')
    endif
  endwhile

  return l:tree
endfunction

" }}}1

function! s:graph.get_map(...) abort dict " {{{1
  let l:force_update = a:0 > 0 ? a:1 : v:false

  if l:force_update
        \ || localtime() - self.map_update_time > self.map_update_freq
    call self.update_map()
  endif

  return deepcopy(self.map)
endfunction

" }}}1
function! s:graph.update_map() abort dict " {{{1
  let self.save_cache = v:false
  let self.map = {}
  for l:file in self.get_files()
    let self.map[l:file] = {
          \ 'out': self.get_links_from(l:file),
          \ 'in': []
          \}
  endfor
  let self.save_cache = v:true
  call self.cache.write()

  for l:file in values(self.map)
    for l:link in l:file.out
      if !has_key(self.map, l:link.filename_to)
        let self.map[l:link.filename_to] = {
              \ 'out': [],
              \ 'in': [l:link]
              \}
      else
        call add(self.map[l:link.filename_to].in, l:link)
      endif
    endfor
  endfor

  let self.map_update_time = localtime()
endfunction

" }}}1
