" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#cache#path(name) abort " {{{1
  let l:root = expand(g:wiki_cache_root)
  if !isdirectory(l:root)
    call mkdir(l:root, 'p')
  endif

  return wiki#paths#join(l:root, a:name)
endfunction

" }}}1

function! wiki#cache#open(name, ...) abort " {{{1
  let l:opts = extend({
        \ 'local': v:false,
        \ 'default': 0,
        \ 'persistent': get(g:, 'wiki_cache_persistent', v:true),
        \ 'validate': s:_version,
        \}, a:0 > 0 ? a:1 : {})

  let l:project_local = remove(l:opts, 'local')
  return s:cache_open(a:name, l:project_local, l:opts)
endfunction

" }}}1
function! wiki#cache#clear(name) abort " {{{1
  if empty(a:name) | return | endif

  if a:name ==# 'ALL'
    return s:cache_clear_all()
  endif

  let l:persistent = get(g:, 'wiki_cache_persistent', v:true)
  for [l:name, l:cache] in s:cache_get_both(a:name)
    if !empty(l:cache)
      " Note: Clear in place! Other objects (e.g. the graph builder) hold
      " long-lived references to the cache object, so removing it here would
      " leave them with a stale copy that still writes to the same file.
      call l:cache.clear()
    elseif l:persistent
      call delete(wiki#cache#path(l:name . '.json'))
    endif
  endfor
endfunction

" }}}1

function! s:cache_open(name, project_local, opts) abort " {{{1
  let l:name = a:project_local ? s:local_name(a:name) : a:name

  if !has_key(s:caches, l:name)
    let l:path = wiki#cache#path(l:name . '.json')
    let s:caches[l:name] = s:cache.init(l:path, a:opts)
  endif

  return s:caches[l:name]
endfunction

" }}}1
function! s:cache_get(name, ...) abort " {{{1
  let l:project_local = a:0 > 0 ? a:1 : v:false
  let l:name = l:project_local ? s:local_name(a:name) : a:name

  return [l:name, get(s:caches, l:name, {})]
endfunction

" }}}1
function! s:cache_get_both(name) abort " {{{1
  return map(
        \ [v:false, v:true],
        \ { _, x -> s:cache_get(a:name, x) }
        \)
endfunction

" }}}1
function! s:cache_clear_all() abort " {{{1
  " Clear open caches in place (see note in wiki#cache#clear)
  for l:cache in values(s:caches)
    call l:cache.clear()
  endfor

  if !get(g:, 'wiki_cache_persistent', v:true) | return | endif

  " Delete cache files for caches that are not currently open
  for l:file in globpath(g:wiki_cache_root, '*.json', 0, 1)
    call delete(l:file)
  endfor
endfunction

" }}}1

let s:caches = {}
let s:cache = {}

function! s:cache.init(path, opts) dict abort " {{{1
  let l:new = deepcopy(self)
  unlet l:new.init

  let l:new.data = {}
  let l:new.path = a:path
  let l:new.ftime = -1
  let l:new.default = a:opts.default
  let l:new.__validated = 0
  let l:new.__validation_value = deepcopy(a:opts.validate)
  if type(l:new.__validation_value) == v:t_dict
    let l:new.__validation_value._version = s:_version
  endif

  if a:opts.persistent
    return extend(l:new, s:cache_persistent)
  endif

  return extend(l:new, s:cache_volatile)
endfunction

" }}}1

let s:cache_persistent = {
      \ 'type': 'persistent',
      \ 'modified': v:false,
      \}
function! s:cache_persistent.validate() dict abort " {{{1
  if self.__validated | return | endif
  let self.__validated = 1

  if empty(self.data)
    let self.data.__validate = deepcopy(self.__validation_value)
    return
  endif

  if !has_key(self.data, '__validate')
        \ || type(self.data.__validate) != type(self.__validation_value)
        \ || self.data.__validate != self.__validation_value
    call self.clear()
    let self.data.__validate = deepcopy(self.__validation_value)
  endif
endfunction

" }}}1
function! s:cache_persistent.get(key) dict abort " {{{1
  call self.read()

  if !has_key(self.data, a:key)
    let self.data[a:key] = deepcopy(self.default)
  endif

  return self.data[a:key]
endfunction

" }}}1
function! s:cache_persistent.has(key) dict abort " {{{1
  call self.read()

  return has_key(self.data, a:key)
endfunction

" }}}1
function! s:cache_persistent.set(key, value) dict abort " {{{1
  call self.read()

  let self.data[a:key] = a:value
  call self.write(1)

  return a:value
endfunction

" }}}1
function! s:cache_persistent.write(...) dict abort " {{{1
  call self.read()

  let l:modified = self.modified || a:0 > 0
  if !l:modified || empty(self.data) | return | endif

  call writefile([json_encode(self.data)], self.path)
  let self.ftime = getftime(self.path)
  let self.modified = v:false
endfunction

" }}}1
function! s:cache_persistent.read() dict abort " {{{1
  if getftime(self.path) <= self.ftime
    return self.validate()
  endif

  let self.ftime = getftime(self.path)

  " Note: A cache file may be unreadable or corrupted, e.g. if Vim was killed
  " while writing it. There is nothing to recover in that case, so we discard
  " the cache and let it be rebuilt.
  try
    let l:contents = join(readfile(self.path))
    if empty(l:contents) | return | endif

    let l:data = json_decode(l:contents)
  catch
    call wiki#log#warn(
          \ 'Could not read cache file (discarding it):',
          \ self.path
          \)
    call self.clear()
    return
  endtry

  if type(l:data) != v:t_dict
    call wiki#log#warn(
          \ 'Inconsistent cache data while reading (discarding it):',
          \ self.path,
          \ 'Decoded data type: ' . type(l:data)
          \)
    call self.clear()
    return
  endif

  call extend(self.data, l:data, 'keep')
  call self.validate()
endfunction

" }}}1
function! s:cache_persistent.clear() dict abort " {{{1
  let self.data = { '__validate': deepcopy(self.__validation_value) }
  let self.ftime = -1
  let self.modified = v:false
  call delete(self.path)
endfunction

" }}}1

let s:cache_volatile = {
      \ 'type': 'volatile',
      \}
function! s:cache_volatile.get(key) dict abort " {{{1
  if !has_key(self.data, a:key)
    let self.data[a:key] = deepcopy(self.default)
  endif

  return self.data[a:key]
endfunction

" }}}1
function! s:cache_volatile.has(key) dict abort " {{{1
  return has_key(self.data, a:key)
endfunction

" }}}1
function! s:cache_volatile.set(key, value) dict abort " {{{1
  let self.data[a:key] = a:value
  let self.ftime = localtime()
  return a:value
endfunction

" }}}1
function! s:cache_volatile.write(...) dict abort " {{{1
  let self.ftime = localtime()
endfunction

" }}}1
function! s:cache_volatile.read() dict abort " {{{1
endfunction

" }}}1
function! s:cache_volatile.clear() dict abort " {{{1
  let self.data = {}
  let self.ftime = -1
endfunction

" }}}1

" Utility functions
function! s:local_name(name) abort " {{{1
  let l:filename = wiki#get_root()
  let l:filename = substitute(l:filename, '\s\+', '_', 'g')
  if exists('+shellslash') && !&shellslash
    let l:filename = substitute(l:filename, '^\(\u\):', '-\1-', '')
    let l:filename = substitute(l:filename, '\\', '-', 'g')
  else
    let l:filename = substitute(l:filename, '\/', '%', 'g')
  endif
  return a:name . l:filename
endfunction

" }}}1


let s:_version = 'cache_v3'

" vim: fdm=marker
