function! coc#source#wiki#init() abort
  let l:filetypes = copy(g:wiki_filetypes)
  let l:index = index(l:filetypes, 'md')
  if l:index >= 0
    let l:filetypes[l:index] = 'markdown'
  endif

  return {
        \ 'priority': 100,
        \ 'name': 'w',
        \ 'shortcut': 'wiki',
        \ 'filetypes': l:filetypes,
        \ 'triggerCharacters': ['/', '#', '@'],
        \}
endfunction

function! coc#source#wiki#get_startcol(opt) abort
  let l:line = a:opt['line'][:a:opt['colnr'] - 2]
  return wiki#complete#findstart(l:line)
endfunction

function! coc#source#wiki#should_complete(opt) abort
  let l:line = a:opt['line'][:a:opt['colnr'] - 1]
  return wiki#complete#findstart(l:line) >= 0
endfunction

function! coc#source#wiki#complete(opt, cb) abort
  let l:items = wiki#complete#complete(a:opt.input)

  for l:x in l:items
    let l:x.menu = ''
  endfor

  call a:cb(l:items)
endfunction
