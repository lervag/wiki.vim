" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#graph#find_backlinks() abort "{{{1
  let l:file = expand('%:p')
  if !filereadable(l:file)
    call wiki#log#info("Can't find backlinks for unsaved file!")
    return []
  endif

  let l:graph = wiki#graph#builder#get()
  let l:links = l:graph.get_links_to(l:file)
  if empty(l:links)
    call wiki#log#info('No other file links to this file')
    return
  endif

  for l:link in l:links
    let l:link.filename = l:link.filename_from
    let l:link.text = readfile(l:link.filename, 0, l:link.lnum)[-1]
  endfor

  call setloclist(0, l:links, 'r')
  lopen
endfunction

"}}}1

function! wiki#graph#check_links(...) abort "{{{1
  let l:graph = wiki#graph#builder#get()

  if a:0 > 0
    let l:broken_links = l:graph.get_broken_links_from(a:1)
  else
    let l:broken_links = l:graph.get_broken_links_global()
  endif

  if empty(l:broken_links)
    call wiki#log#info('No broken links found.')
    return
  endif

  call map(l:broken_links,
        \ { _, x -> {
        \   'filename': x.filename_from,
        \   'text': x.content,
        \   'anchor': x.anchor,
        \   'lnum': x.lnum,
        \   'col': x.col
        \ }
        \})

  call setloclist(0, l:broken_links, 'r')
  lopen
endfunction

"}}}1

function! wiki#graph#in(...) abort "{{{1
  let l:graph = wiki#graph#builder#get()

  let l:depth = a:0 > 0 ? a:1 : -1
  let l:tree = l:graph.get_tree_to(expand('%:p'), l:depth)

  call s:output_to_scratch('WikiGraphIn', sort(values(l:tree)))
endfunction

"}}}1
function! wiki#graph#out(...) abort " {{{1
  let l:graph = wiki#graph#builder#get()

  let l:depth = a:0 > 0 ? a:1 : -1
  let l:tree = l:graph.get_tree_from(expand('%:p'), l:depth)

  call s:output_to_scratch('WikiGraphOut', sort(values(l:tree)))
endfunction

" }}}1


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
