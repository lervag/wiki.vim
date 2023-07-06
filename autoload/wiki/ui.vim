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
function! wiki#ui#clear_buffer() abort " {{{1
  if empty(s:buffer) | return | endif
  let l:cmdheight = &cmdheight
  let &cmdheight = len(s:buffer) + 2

  echo repeat('-', winwidth(0)-1) . "\n" . join(s:buffer, "\n")
  let s:buffer = []

  let &cmdheight = l:cmdheight
endfunction

let g:wiki#ui#buffered = get(g:, 'wiki#ui#buffered', v:false)
let s:buffer = []

" }}}1

function! wiki#ui#confirm(prompt) abort " {{{1
  return has('nvim')
        \ ? wiki#ui#nvim#confirm(a:prompt)
        \ : wiki#ui#legacy#confirm(a:prompt)
endfunction

" }}}1
function! wiki#ui#input(options) abort " {{{1
  let l:options = extend(#{
        \ prompt: '> ',
        \ text: '',
        \ info: '',
        \}, a:options)

  return has('nvim')
        \ ? wiki#ui#nvim#input(l:options)
        \ : wiki#ui#legacy#input(l:options)
endfunction

" }}}1
function! wiki#ui#select(container, ...) abort " {{{1
  if empty(a:container) | return '' | endif

  let l:options = extend(
        \ {
        \   'abort': v:true,
        \   'prompt': 'Please choose item:',
        \   'return': 'value',
        \ },
        \ a:0 > 0 ? a:1 : {})
  let l:return_type = remove(l:options, 'return')

  let l:list = type(a:container) == v:t_dict
        \ ? values(a:container)
        \ : a:container
  let [l:index, l:value] = has('nvim')
        \ ? wiki#ui#nvim#select(l:list, l:options)
        \ : wiki#ui#legacy#select(l:list, l:options)

  if l:return_type ==# 'value'
    return l:value
  endif

  if type(a:container) == v:t_dict
    return l:index >= 0 ? keys(a:container)[l:index] : ''
  endif

  return l:index
endfunction

" }}}1

function! s:echo_string(msg, opts) abort " {{{1
  let l:msg = repeat(' ', a:opts.indent) . a:msg

  if g:wiki#ui#buffered
    call add(s:buffer, l:msg)
  else
    echo l:msg
  endif
endfunction

" }}}1
function! s:echo_formatted(parts, opts) abort " {{{1
  if g:wiki#ui#buffered
    let l:message = repeat(' ', a:opts.indent)
    for l:part in a:parts
      let l:message .= type(l:part) == v:t_list ? l:part[1] : l:part
    endfor
    call add(s:buffer, l:message)
    return
  endif

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
