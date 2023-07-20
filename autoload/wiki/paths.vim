" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#paths#pushd(path) abort " {{{1
  if empty(a:path) || getcwd() ==# fnamemodify(a:path, ':p')
    let s:qpath += ['']
  else
    let s:qpath += [getcwd()]
    execute s:cd fnameescape(a:path)
  endif
endfunction

" }}}1
function! wiki#paths#popd() abort " {{{1
  let l:path = remove(s:qpath, -1)
  if !empty(l:path)
    execute s:cd fnameescape(l:path)
  endif
endfunction

" }}}1

function! wiki#paths#join(root, tail) abort " {{{1
  return wiki#paths#s(a:root . '/' . a:tail)
endfunction

" }}}1

function! wiki#paths#s(path) abort " {{{1
  " Handle shellescape issues and simplify path
  let l:path = exists('+shellslash') && !&shellslash
        \ ? tr(a:path, '/', '\')
        \ : a:path

  return simplify(l:path)
endfunction

" }}}1
function! wiki#paths#is_abs(path) abort " {{{1
  return a:path =~# s:re_abs
endfunction

" }}}1

function! wiki#paths#shorten_relative(path) abort " {{{1
  " Input: An absolute path
  " Output: Relative path with respect to the wiki root, unless absolute path
  "         is shorter

  let l:relative = wiki#paths#relative(a:path, wiki#get_root())
  return strlen(l:relative) < strlen(a:path)
        \ ? l:relative : a:path
endfunction

" }}}1
function! wiki#paths#relative(path, current) abort " {{{1
  " Note: This algorithm is based on the one presented by @Offirmo at SO,
  "       http://stackoverflow.com/a/12498485/51634

  let l:target = simplify(substitute(a:path, '\\', '/', 'g'))
  let l:common = simplify(substitute(a:current, '\\', '/', 'g'))

  " This only works on absolute paths
  if !wiki#paths#is_abs(l:target)
    return substitute(a:path, '^\.\/', '', '')
  endif

  let l:tries = 50
  let l:result = ''
  while stridx(l:target, l:common) != 0 && l:tries > 0
    let l:common = fnamemodify(l:common, ':h')
    let l:result = empty(l:result) ? '..' : '../' . l:result
    let l:tries -= 1
  endwhile

  if l:tries == 0 | return a:path | endif

  if l:common ==# '/'
    let l:result .= '/'
  endif

  let l:forward = strpart(l:target, strlen(l:common))
  if !empty(l:forward)
    let l:result = empty(l:result)
          \ ? l:forward[1:]
          \ : l:result . l:forward
  endif

  return l:result
endfunction

" }}}1
function! wiki#paths#to_node(path) abort " {{{1
  " Input: An absolute path
  " Output: Relative path without extension with respect to the wiki root,
  "         unless absolute path is shorter (a "node")

  return fnamemodify(wiki#paths#shorten_relative(a:path), ':r')
endfunction

" }}}1
function! wiki#paths#to_wiki_url(path, root) abort " {{{1
  " Input: An absolute path
  " Output: A wiki url (relative to specified root)

  let l:path = wiki#paths#relative(a:path, a:root)
  let l:ext = '.' . fnamemodify(l:path, ':e')

  return l:ext ==# wiki#link#get_creator('url_extension')
        \ ? l:path
        \ : fnamemodify(l:path, ':r')
endfunction

" }}}1

function! wiki#paths#get_filetype(path) abort " {{{1
  return get(#{
        \ md: 'markdown',
        \ adoc: 'asciidoc',
        \ wiki: 'wiki',
        \ org: 'org',
        \},
        \ fnamemodify(a:path, ':e'),
        \ !empty(&filetype) ? &filetype : 'wiki')
endfunction

" }}}1

let s:cd = haslocaldir()
      \ ? 'lcd'
      \ : exists(':tcd') && haslocaldir(-1) ? 'tcd' : 'cd'
let s:qpath = get(s:, 'qpath', [])

let s:re_abs = has('win32') ? '^[A-Z]:[\\/]' : '^/'
