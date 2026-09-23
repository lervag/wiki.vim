" A wiki plugin for Vim
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
      \ '_cache_save': v:true,
      \ '_cache_threshold_full': 7200,
      \ '_cache_threshold_fast': 30,
      \ '_cache_updated': [],
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
          \       wiki#link#get_all_from_file(a:file),
          \       { _, x -> extend(x, x.resolve()) }
          \     ),
          \     { _, x ->
          \       index(['wiki', 'md'], x.scheme) >= 0
          \       && a:file !=# resolve(x.path)
          \     }
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

    if self._cache_save
      call self.cache_links_out.write('force')
    else
      let self.cache_links_out.modified = v:true
    endif

    call add(self._cache_updated, a:file)
  endif

  return deepcopy(l:current.links)
endfunction

" }}}1
function! s:graph.get_links_to(file, ...) abort dict " {{{1
  call self.refresh_cache(a:0 > 0 ? a:1 : {})
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

  let self._cache_save = v:false
  for l:file in self.get_files()
    call extend(l:broken_links, self.get_broken_links_from(l:file))
  endfor
  let self._cache_save = v:true
  call self.cache_links_out.write()

  return l:broken_links
endfunction

" }}}1

function! s:graph.get_tree_to(file, depth) abort dict " {{{1
  call self.refresh_cache()

  return self._build_tree(a:file, a:depth, 'in')
endfunction

" }}}1
function! s:graph.get_tree_from(file, depth) abort dict " {{{1
  return self._build_tree(a:file, a:depth, 'out')
endfunction

" }}}1

function! s:graph._build_tree(file, depth, direction) abort dict " {{{1
  " Build a tree of the files that are reachable from a:file by following
  " links in the specified direction ('in' or 'out'). The tree is a nested
  " structure of nodes:
  "
  "   {
  "     'file': absolute path,
  "     'node': node name (see wiki#paths#to_node),
  "     'cycle': v:true if the node links back to one of its ancestors,
  "     'children': list of nodes,
  "   }
  "
  " Each file is only expanded once, i.e. the tree is a spanning tree where
  " every file is attached to the closest parent. Links back to an ancestor
  " are kept as leaf nodes marked with "cycle", whereas other links to
  " already visited files are dropped.

  let l:root = s:tree_node(a:file)
  let l:visited = { a:file : 1 }
  let l:queue = [[l:root, [a:file]]]

  while !empty(l:queue)
    let [l:current, l:ancestors] = remove(l:queue, 0)
    if a:depth > 0 && len(l:ancestors) > a:depth | continue | endif

    for l:file in self._get_adjacent_files(l:current.file, a:direction)
      if has_key(l:visited, l:file)
        if index(l:ancestors, l:file) >= 0
          call add(l:current.children, s:tree_node(l:file, v:true))
        endif
        continue
      endif
      let l:visited[l:file] = 1

      let l:child = s:tree_node(l:file)
      call add(l:current.children, l:child)
      call add(l:queue, [l:child, l:ancestors + [l:file]])
    endfor
  endwhile

  return l:root
endfunction

" }}}1
function! s:graph._get_adjacent_files(file, direction) abort dict " {{{1
  let l:files = a:direction ==# 'in'
        \ ? map(copy(get(self.cache_links_in.data, a:file, [])),
        \       { _, x -> x.filename_from })
        \ : map(self.get_links_from(a:file),
        \       { _, x -> x.filename_to })

  return wiki#u#uniq_unsorted(sort(l:files, 'i'))
endfunction

" }}}1

function! s:tree_node(file, ...) abort " {{{1
  return {
        \ 'file': a:file,
        \ 'node': wiki#paths#to_node(a:file),
        \ 'cycle': a:0 > 0 ? a:1 : v:false,
        \ 'children': [],
        \}
endfunction

" }}}1

function! s:graph.mark_refreshed(file) abort " {{{1
  call add(self._cache_updated, a:file)
endfunction

" }}}1
function! s:graph.mark_tainted(file) abort dict " {{{1
  if empty(a:file) | return | endif

  for l:link in self.cache_links_in.get(a:file)
    call add(self._cache_updated, l:link.filename_from)
  endfor

  if !filereadable(a:file)
    unlet! self.cache_links_in.data[a:file]
  endif
endfunction

" }}}1

function! s:graph.refresh_cache(...) abort dict " {{{1
  let l:opts = extend({
        \ 'force': v:false,
        \ 'nudge': v:false,
        \}, a:0 > 0 ? a:1 : {})

  call self.cache_links_in.read()

  let l:secs_since_updated = localtime() - self.cache_links_in.ftime
  if l:opts.force || (l:secs_since_updated > self._cache_threshold_full)
    let self._cache_save = v:false
    call self._refresh_cache_full()
  elseif l:opts.nudge || l:secs_since_updated > self._cache_threshold_fast
    let self._cache_save = v:false
    call self._refresh_cache_fast()
  else
    return
  endif

  call self.cache_links_out.write()
  call self.cache_links_in.write('force')

  let self._cache_save = v:true
  let self._cache_updated = []
endfunction

" }}}1
function! s:graph._refresh_cache_fast() abort dict " {{{1
  for l:file in wiki#u#uniq_unsorted(self._cache_updated)
    if !has_key(self.cache_links_in.data, l:file)
      let self.cache_links_in.data[l:file] = []
    endif

    " We need to force refresh the links_out cache because getftime is
    " restricted to a temporal resolution of 1 second. If we did not do this,
    " then the tests will fail.
    if has_key(self.cache_links_out.data, l:file)
      let self.cache_links_out.data[l:file].ftime -= 1
    endif

    " This is similar to the full refresh, except we only add the link if it is
    " not already there.
    for l:link in self.get_links_from(l:file)
      if !has_key(self.cache_links_in.data, l:link.filename_to)
        let self.cache_links_in.data[l:link.filename_to] = [l:link]
      elseif index(self.cache_links_in.data[l:link.filename_to], l:link) < 0
        call add(self.cache_links_in.data[l:link.filename_to], l:link)
      endif
    endfor
  endfor
endfunction

" }}}1
function! s:graph._refresh_cache_full() abort dict " {{{1
  call self.cache_links_in.clear()

  " Refresh cache for links_out and links_in in entire wiki
  for l:file in self.get_files()
    if !has_key(self.cache_links_in.data, l:file)
      let self.cache_links_in.data[l:file] = []
    endif

    for l:link in self.get_links_from(l:file)
      if !has_key(self.cache_links_in.data, l:link.filename_to)
        let self.cache_links_in.data[l:link.filename_to] = [l:link]
      else
        call add(self.cache_links_in.data[l:link.filename_to], l:link)
      endif
    endfor
  endfor

  let self.cache_links_in.modified = v:true
endfunction

" }}}1
