function! wiki#fzf#pages() abort
  if !exists('*fzf#run')
    echo "fzf must be installed for this to work"
    return
  endif
  let l:root = wiki#get_root()

  let l:pattern = '**/*.' . join(g:wiki_filetypes, ',')
  let l:pages = split(globpath(l:root, l:pattern))
  let l:pages = map(l:pages, '"/".substitute(v:val, l:root . "/" , "", "")')

  call fzf#run({
  \   'source': l:pages,
  \   'sink': funcref('s:pages_accept'),
  \   'options': '--prompt "WikiPages> " '
  \ })
endfunction

function! s:pages_accept(line) abort
  let l:root = wiki#get_root()
  let l:fname = l:root . a:line
  execute 'edit ' . l:fname
endfunction

function! wiki#fzf#toc() abort
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

  call fzf#run({
  \   'source': reverse(l:lines),
  \   'sink': funcref('s:toc_accept'),
  \   'options': join([
  \       '--prompt "WikiToc> "',
  \       '--delimiter "\\|"',
  \       '--with-nth "2.."'
  \   ], ' ')
  \ })
endfunction

function! s:toc_accept(line) abort
  let l:parts = split(a:line, '|')
  let l:lnum = l:parts[0]
  execute l:lnum
endfunction
