function! wiki#fzf#pages() abort "{{{1
  if !exists('*fzf#run')
    echo "fzf must be installed for this to work"
    return
  endif
  let l:root = wiki#get_root()

  if len(g:wiki_filetypes) == 1
    let l:pattern = '**/*.' . g:wiki_filetypes[0]
  else
    let l:pattern = '**/*.{' . join(g:wiki_filetypes, ',') . '}'
  endif
  let l:pages = globpath(l:root, l:pattern, v:false, v:true)
  let l:pages = map(l:pages, '"/".substitute(v:val, l:root . "/" , "", "")')

  call fzf#run(fzf#wrap({
  \     'source': l:pages,
  \     'sink': funcref('s:pages_accept'),
  \     'options': '--prompt "WikiPages> " '
  \ }))
endfunction

" }}}1
function! s:pages_accept(line) abort "{{{1
  let l:root = wiki#get_root()
  let l:fname = l:root . a:line
  execute 'edit ' . l:fname
endfunction

" }}}1
function! wiki#fzf#toc() abort "{{{1
  if !exists('*fzf#run')
    echo "fzf must be installed for this to work"
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
  \     'source': reverse(l:lines),
  \     'sink': funcref('s:toc_accept'),
  \     'options': join([
  \           '--prompt "WikiToc> "',
  \           '--delimiter "\\|"',
  \           '--with-nth "2.."'
  \     ], ' ')
  \ }))
endfunction

"}}}1
function! s:toc_accept(line) abort "{{{1
  let l:parts = split(a:line, '|')
  let l:lnum = l:parts[0]
  execute l:lnum
endfunction

"}}}1
