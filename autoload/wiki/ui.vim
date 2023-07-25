" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#ui#echo(input, ...) abort " {{{1
  if empty(a:input) | return | endif
  let l:opts = extend(#{indent: 0}, a:0 > 0 ? a:1 : {})

  if type(a:input) == v:t_string
    call s:echo_string(a:input, l:opts)
  elseif type(a:input) == v:t_list
    call s:echo_formatted(a:input, l:opts)
  elseif type(a:input) == v:t_dict
    call s:echo_dict(a:input, l:opts)
  else
    call wiki#log#warn('Argument not supported: ' . type(a:input))
  endif
endfunction

" }}}1

function! wiki#ui#confirm(prompt) abort " {{{1
  return wiki#ui#{g:wiki_ui_method.confirm}#confirm(a:prompt)
endfunction

" }}}1
function! wiki#ui#input(options) abort " {{{1
  let l:options = extend(#{
        \ prompt: '> ',
        \ text: '',
        \ info: '',
        \}, a:options)

  return wiki#ui#{g:wiki_ui_method.input}#input(l:options)
endfunction

" }}}1
function! wiki#ui#select(container, ...) abort " {{{1
  let l:options = extend(
        \ {
        \   'prompt': 'Please choose item:',
        \   'return': 'value',
        \   'force_choice': v:false,
        \   'auto_select': v:true,
        \ },
        \ a:0 > 0 ? a:1 : {})

  let l:list = type(a:container) == v:t_dict
        \ ? values(a:container)
        \ : a:container
  let [l:index, l:value] = empty(l:list)
        \ ? [-1, '']
        \ : (len(l:list) == 1 && l:options.auto_select
        \   ? [0, l:list[0]]
        \   : wiki#ui#{g:wiki_ui_method.select}#select(l:options, l:list))

  if l:options.return ==# 'value'
    return l:value
  endif

  if type(a:container) == v:t_dict
    return l:index >= 0 ? keys(a:container)[l:index] : ''
  endif

  return l:index
endfunction

" }}}1

function! wiki#ui#get_number(max, digits, force_choice, do_echo) abort " {{{1
  let l:choice = ''

  if a:do_echo
    echo '> '
  endif

  while len(l:choice) < a:digits
    if len(l:choice) > 0 && (l:choice . '0') > a:max
      return l:choice - 1
    endif

    let l:input = nr2char(getchar())

    if !a:force_choice && index(["\<C-c>", "\<Esc>", 'x'], l:input) >= 0
      if a:do_echo
        echon 'aborted!'
      endif
      return -2
    endif

    if len(l:choice) > 0 && l:input ==# "\<cr>"
      return l:choice - 1
    endif

    if l:input !~# '\d' | continue | endif

    if (l:choice . l:input) > 0
      let l:choice .= l:input
      if a:do_echo
        echon l:input
      endif
    endif
  endwhile

  return l:choice - 1
endfunction

" }}}1

function! s:echo_string(msg, opts) abort " {{{1
  let l:msg = repeat(' ', a:opts.indent) . a:msg

  echo l:msg
endfunction

" }}}1
function! s:echo_formatted(parts, opts) abort " {{{1
  echo repeat(' ', a:opts.indent)
  try
    for l:part in a:parts
      if type(l:part) == v:t_string
        echohl None
        echon l:part
      else
        execute 'echohl' l:part[0]
        echon l:part[1]
      endif
      unlet l:part
    endfor
  finally
    echohl None
  endtry
endfunction

" }}}1
function! s:echo_dict(dict, opts) abort " {{{1
  for [l:key, l:val] in items(a:dict)
    call s:echo_formatted([['Label', l:key . ': '], l:val], a:opts)
  endfor
endfunction

" }}}1
