if !exists('g:ctrlp_ext_vars') | finish | endif

call add(g:ctrlp_ext_vars, {
      \ 'init': 'ctrlp#wiki#init()',
      \ 'accept': 'ctrlp#wiki#accept',
      \ 'lname': 'wiki files',
      \ 'sname': 'wf',
      \ 'type': 'path',
      \ 'opmul': 1,
      \ })

let s:id = g:ctrlp_builtins + len(g:ctrlp_ext_vars)

function! ctrlp#wiki#id()
  return s:id
endfunction

function! ctrlp#wiki#init()
  let s:root = wiki#get_root()

  let l:files = systemlist(printf(
        \ (type(g:ctrlp_user_command) == type('')
        \  ? g:ctrlp_user_command
        \  : get(g:ctrlp_user_command, -1)),
        \ s:root))

  call filter(l:files,
        \ 'v:val =~# ''\v%(' . join(g:wiki_filetypes, '|') . ')$''')
  if empty(l:files) | return l:files | endif

  let s:extension = fnamemodify(l:files[0], ':e')
  call map(l:files,
        \ 'strpart(fnamemodify(v:val, '':r''), len(s:root)+1)')

  return sort(l:files)
endfunction

function! ctrlp#wiki#accept(md, path)
  call ctrlp#acceptfile(a:md,
        \ wiki#paths#s(printf('%s/%s.%s', s:root, a:path, s:extension)))
endfunction
