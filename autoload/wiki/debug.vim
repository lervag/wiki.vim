" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#debug#stacktrace(...) abort " {{{1
  "
  " This function builds on Luc Hermite's answer on Stack Exchange:
  " http://vi.stackexchange.com/a/6024/21
  "

  "
  " Get stack and exception
  "
  if empty(v:throwpoint)
    try
      throw 'dummy'
    catch
      let l:stack = reverse(split(v:throwpoint, '\.\.'))[1:]
      let l:exception = 'Manual stacktrace'
    endtry
  else
    let l:stack = reverse(split(v:throwpoint, '\.\.'))
    let l:exception = v:exception
  endif

  "
  " Build the quickfix entries
  "
  let l:qflist = []
  let l:files = {}
  for l:func in l:stack
    try
      let [l:name, l:offset] = (l:func =~# '\S\+\[\d')
            \ ? matchlist(l:func, '\(\S\+\)\[\(\d\+\)\]')[1:2]
            \ : matchlist(l:func, '\(\S\+\), line \(\d\+\)')[1:2]
    catch
      let l:name = l:func
      let l:offset = 0
    endtry

    if l:name =~# '\v(\<SNR\>|^)\d+_'
      let l:sid = matchstr(l:name, '\v(\<SNR\>|^)\zs\d+\ze_')
      let l:name  = substitute(l:name, '\v(\<SNR\>|^)\d+_', 's:', '')
      let l:filename = substitute(
            \ wiki#u#command('scriptnames')[l:sid-1],
            \ '^\s*\d\+:\s*', '', '')
    else
      let l:func_name = l:name =~# '^\d\+$' ? '{' . l:name . '}' : l:name
      let l:func_lines = wiki#u#command('verbose function ' . l:func_name)
      if len(l:func_lines) > 1
        let l:filename = matchstr(
              \ l:func_lines[1],
              \ v:lang[0:1] ==# 'en'
              \   ? 'Last set from \zs.*\.vim' : '\f\+\.vim')
      else
        let l:filename = 'NOFILE'
      endif
    endif

    let l:filename = fnamemodify(l:filename, ':p')
    if filereadable(l:filename)
      if !has_key(l:files, l:filename)
        let l:files[l:filename] = reverse(readfile(l:filename))
      endif

      if l:name =~# '^\d\+$'
        let l:lnum = 0
        let l:output = wiki#u#command('function {' . l:name . '}')
        let l:text = substitute(
              \ matchstr(l:output, '^\s*' . l:offset),
              \ '^\d\+\s*', '', '')
      else
        let l:lnum = l:offset + len(l:files[l:filename])
              \ - match(l:files[l:filename], '^\s*fu\%[nction]!\=\s\+' . l:name .'(')
        let l:lnum_rev = len(l:files[l:filename]) - l:lnum
        let l:text = substitute(l:files[l:filename][l:lnum_rev], '^\s*', '', '')
      endif
    else
      let l:filename = ''
      let l:lnum = 0
      let l:text = ''
    endif

    call add(l:qflist, {
          \ 'filename': l:filename,
          \ 'function': l:name,
          \ 'lnum': l:lnum,
          \ 'text': len(l:qflist) == 0 ? l:exception : l:text,
          \ 'nr': len(l:qflist),
          \})
  endfor

  " Fill in empty filenames
  let l:prev_filename = '_'
  call reverse(l:qflist)
  for l:entry in l:qflist
    if empty(l:entry.filename)
      let l:entry.filename = l:prev_filename
    endif
    let l:prev_filename = l:entry.filename
  endfor
  call reverse(l:qflist)

  if a:0 > 0
    call setqflist(l:qflist)
    execute 'copen' len(l:qflist) + 2
    wincmd p
  endif

  return l:qflist
endfunction

" }}}1
function! wiki#debug#time(...) abort " {{{1
  let l:t1 = reltimefloat(reltime())

  if a:0 > 0
    call wiki#log#warn(printf(
          \ "%s: %8.5f\n",
          \ a:0 > 1 ? a:2 : 'Time elapsed', l:t1 - a:1))
  endif

  return l:t1
endfunction

" }}}1

function! wiki#debug#profile_start() abort " {{{1
  profile start prof.log
  profile func *
endfunction

" }}}1
function! wiki#debug#profile_stop() abort " {{{1
  profile stop
  call s:fix_sids()
endfunction

" }}}1

function! s:fix_sids() abort " {{{1
  let l:lines = readfile('prof.log')
  let l:new = []
  for l:line in l:lines
    let l:sid = matchstr(l:line, '\v\<SNR\>\zs\d+\ze_')
    if !empty(l:sid)
      let l:filename = map(
            \ wiki#u#command('scriptnames'),
            \ {_, x -> split(x, '\v:=\s+')[1]})[l:sid-1]
      if l:filename =~# 'vimtex'
        let l:filename = substitute(l:filename, '^.*autoload\/', '', '')
        let l:filename = substitute(l:filename, '\.vim$', '#s:', '')
        let l:filename = substitute(l:filename, '\/', '#', 'g')
      else
        let l:filename .= ':'
      endif
      call add(l:new, substitute(l:line, '\v\<SNR\>\d+_', l:filename, 'g'))
    else
      call add(l:new, substitute(l:line, '\s\+$', '', ''))
    endif
  endfor
  call writefile(l:new, 'prof.log')
endfunction

" }}}1
