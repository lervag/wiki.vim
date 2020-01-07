" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#fzf#pages() abort "{{{1
  if !exists('*fzf#run')
    echo 'fzf must be installed for this to work'
    return
  endif

  let l:pattern = '**/*.' . (len(g:wiki_filetypes) == 1
        \ ? g:wiki_filetypes[0] : '{' . join(g:wiki_filetypes, ',') . '}')

  let l:root = wiki#get_root()
  let l:pages = globpath(l:root, l:pattern, v:false, v:true)
  let l:pages = map(l:pages, '"/" . substitute(v:val, l:root . "/" , "", "")')

  call fzf#run(fzf#wrap({
        \ 'source': l:pages,
        \ 'sink': funcref('s:accept_page'),
        \ 'options': '--prompt "WikiPages> " '
        \}))
endfunction

" }}}1
function! wiki#fzf#tags() abort "{{{1
  if !exists('*fzf#run')
    echo 'fzf must be installed for this to work'
    return
  endif

  let l:tags = wiki#tags#get_all()
  let l:results = []
  for [l:key, l:val] in items(l:tags)
    for [l:file, l:lnum, l:col] in l:val
      let l:results += [l:key . ': ' . l:file . ':' . l:lnum]
    endfor
  endfor

  call fzf#run(fzf#wrap({
        \ 'source': l:results,
        \ 'sink': funcref('s:accept_tag'),
        \ 'options': '--prompt "WikiTags> " '
        \}))
endfunction

" }}}1
function! wiki#fzf#toc() abort "{{{1
  if !exists('*fzf#run')
    echo 'fzf must be installed for this to work'
    return
  endif

  let l:toc = wiki#page#gather_toc_entries(v:false)
  let l:lines = []
  for l:entry in l:toc
    let l:indent = repeat('.', l:entry.level - 1)
    let l:line = l:entry.lnum . '|' . l:indent . l:entry.header_text
    call add(l:lines, l:line)
  endfor

  call fzf#run(fzf#wrap({
        \ 'source': reverse(l:lines),
        \ 'sink': funcref('s:accept_toc_entry'),
        \ 'options': join([
        \       '--prompt "WikiToc> "',
        \       '--delimiter "\\|"',
        \       '--with-nth "2.."'
        \ ], ' ')
        \}))
endfunction

"}}}1

function! s:accept_page(line) abort "{{{1
  execute 'edit ' . wiki#get_root() . a:line
endfunction

" }}}1
function! s:accept_tag(tag) abort "{{{1
  let [l:file, l:lnum] = split(a:tag, ':')[1:]
  execute 'edit ' . l:file
  execute l:lnum
endfunction

" }}}1
function! s:accept_toc_entry(line) abort "{{{1
  let l:lnum = split(a:line, '|')[0]
  execute l:lnum
endfunction

"}}}1
