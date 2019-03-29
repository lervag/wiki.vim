" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#tags#search(...) abort " {{{1
  let l:cfg = deepcopy(g:wiki_tags)
  let l:cfg.tag = ''

  let l:args = copy(a:000)
  while !empty(l:args)
    let l:arg = remove(l:args, 0)
    if l:arg ==# '-output'
      let l:cfg.output = remove(l:args, 0)
    elseif empty(l:cfg.tag)
      let l:cfg.tag = l:arg
    else
      echomsg 'WikiTagSeach: Argument "' . l:arg . '" not recognized'
      echomsg '              Please see :help WikiTagSearch'
      return
    endif
  endwhile

  if empty(l:cfg.tag)
    let l:cfg.tag = input('Specify tag: ')
    echo "\n"
  endif

  try
    call s:output_{l:cfg.output}(l:cfg.tag)
  catch /E117/
    echomsg 'WikiTagSeach: Output type "' . l:cfg.output . '" not recognized!'
    echomsg '              Please see :help WikiTagSearch'
  endtry
endfunction

" }}}1


function! s:output_loclist(tag) abort " {{{1
  call s:tags.gather()
  let l:tags = get(s:tags.collection, a:tag, [])

  if empty(l:tags)
    echo 'Tag not found:' a:tag
    return
  endif

  let l:list = []
  for [l:file, l:lnum, l:col] in l:tags
    call add(l:list, {
          \ 'filename' : l:file,
          \ 'lnum' : l:lnum,
          \ 'col' : l:col,
          \ 'text' : a:tag,
          \})
  endfor

  call setloclist(0, [], ' ', {'title': 'WikiTagSearch', 'items': l:list})
endfunction

" }}}1
function! s:output_echo(tag) abort " {{{1
  call s:tags.gather()
  let l:tags = get(s:tags.collection, a:tag, [])

  if empty(l:tags)
    echo 'Tag not found:' a:tag
    return
  endif

  for [l:file, l:lnum, l:col] in l:tags
    echo printf('- %s (%s:%s)', fnamemodify(l:file, ':t'), l:lnum, l:col)
  endfor
endfunction

" }}}1


let s:tags = {
      \ 'collection' : {},
      \ 'parsed' : 0,
      \}

function! s:tags.gather() abort dict " {{{1
  if !self.parsed
    for l:file in globpath(b:wiki.root, '**/*.' . b:wiki.extension, 0, 1)
      call self.gather_from_file(l:file)
    endfor
    let self.parser = 1
  endif

  return self.collection
endfunction

" }}}1
function! s:tags.gather_from_file(file) abort dict " {{{1
  let l:lnum = 0
  for l:line in readfile(a:file, 0, 15)
    let l:lnum += 1
    let l:col = 0

    while v:true
      let [l:tag, l:pos, l:col] = matchstrpos(l:line, '\v%(^|\s):\zs[^: ]+\ze:', l:col)
      if l:col == -1 | break | endif

      call self.add(l:tag, a:file, l:lnum, l:pos)
    endwhile
  endfor
endfunction

" }}}1
function! s:tags.add(tag, ...) abort dict " {{{1
  if !has_key(self.collection, a:tag)
    let self.collection[a:tag] = []
  endif

  call add(self.collection[a:tag], a:000)
endfunction

" }}}1
