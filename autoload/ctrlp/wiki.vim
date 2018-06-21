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
  let l:root = wiki#get_root()

  let l:files = systemlist(printf(
        \ (type(g:ctrlp_user_command) == type('')
        \  ? g:ctrlp_user_command
        \  : get(g:ctrlp_user_command, -1)),
        \ l:root))

  call filter(l:files, 'v:val =~# ''wiki$''')
  let l:files = map(l:files,
        \ 'strpart(fnamemodify(v:val, '':r''), len(l:root)+1)')

  return sort(l:files)
endfunction

function! ctrlp#wiki#accept(md, path)
  execute 'edit' a:path . '.wiki'
endfunction
