" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#graph#builder#get() abort " {{{1
  let l:root = wiki#get_root()

  if !has_key(s:graphs, l:root)
    let s:graphs[l:root] = s:graph.create(l:root)
  endif

  return s:graphs[l:root]
endfunction

let s:graphs = {}

" }}}1


let s:graph = {
      \ 'save_cache': v:true,
      \ '_cache_threshold': 7200,
      \ '_cache_threshold_def': 7200,
      \}

function! s:graph.create(root) abort dict " {{{1
  let l:new = deepcopy(s:graph)
  unlet l:new.create

  let l:new.root = a:root
  let l:new.extension = exists('b:wiki.extension')
        \ ? b:wiki.extension
        \ : g:wiki_filetypes[0]
  let l:new.cache_links_in = wiki#cache#open('links-in', {
        \ 'local': 1,
        \ 'default': [],
        \})
  let l:new.cache_links_out = wiki#cache#open('links-out', {
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
  if empty(a:file) || !filereadable(a:file) |  return [] | endif

  let l:current = self.cache_links_out.get(a:file)

  let l:ftime = getftime(a:file)
  if l:ftime > l:current.ftime
    let l:current.ftime = l:ftime
    let l:current.links =
          \ map(
          \   filter(
          \     map(
          \       wiki#link#get_all(a:file),
          \       { _, x -> extend(x, x.resolve()) }
          \     ),
          \     { _, x -> x.scheme ==# 'wiki' && a:file !=# resolve(x.path) }
          \   ),
          \   { _, x -> {
          \       'filename_from' : a:file,
          \       'filename_to' : resolve(x.path),
          \       'content' : x.content,
          \       'text' : x.text,
          \       'anchor' : '#' . x.anchor,
          \       'lnum' : x.pos_start[0],
          \       'col' : x.pos_start[1]
          \     }
          \   }
          \)

    let self.cache_links_out.modified = 1
    if self.save_cache
      call self.cache_links_out.write()
    endif
  endif

  return deepcopy(l:current.links)
endfunction

" }}}1
function! s:graph.get_links_to(file, ...) abort dict " {{{1
  if a:0 > 0
    let self._cache_threshold = a:1
    call self.refresh_cache_links_in()
    let self._cache_threshold = self._cache_threshold_def
  else
    call self.refresh_cache_links_in()
  endif

  return deepcopy(self.cache_links_in.get(a:file))
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
  call self.cache_links_out.write()

  return l:broken_links
endfunction

" }}}1

function! s:graph.get_tree_to(file, depth) abort " {{{1
  call self.refresh_cache_links_in()

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
          \ deepcopy(get(self.cache_links_in.data, l:file, [])),
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

function! s:graph.refresh_cache_links_in(...) abort dict " {{{1
  let l:force_update = a:0 > 0 ? a:1 : v:false
  if !l:force_update
        \ && (localtime() - self.cache_links_in.ftime <= self._cache_threshold)
    return
  endif

  call self.cache_links_in.clear()

  " Refresh links_out for entire wiki
  let self.save_cache = v:false
  for l:file in self.get_files()
    call self.get_links_from(l:file)
    let self.cache_links_in.data[l:file] = []
  endfor
  let self.save_cache = v:true
  call self.cache_links_out.write()

  " Populate links_in
  for l:file_with_links in values(self.cache_links_out.data)
    if type(l:file_with_links) == v:t_dict
      for l:link in l:file_with_links.links
        if !has_key(self.cache_links_in.data, l:link.filename_to)
          let self.cache_links_in.data[l:link.filename_to] = [l:link]
        else
          call add(self.cache_links_in.data[l:link.filename_to], l:link)
        endif
      endfor
    endif
  endfor

  call self.cache_links_in.write('force')

  if self.cache_links_in.type ==# 'volatile'
    let self.cache_links_in.ftime = localtime()
  endif
endfunction

" }}}1
