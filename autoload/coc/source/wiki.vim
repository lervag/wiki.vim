function! coc#source#wiki#init() abort
  return {
        \ 'priority': 100,
        \ 'name': 'w',
        \ 'shortcut': 'wiki',
        \ 'filetypes': g:wiki_filetypes,
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
