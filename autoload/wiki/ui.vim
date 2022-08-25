" A simple wiki plugin for Vim
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
function! s:echo_clear_buffer() abort " {{{1
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


function! wiki#ui#input(prompt, ...) abort " {{{1
  let l:opts = extend(#{text: ''}, a:0 > 0 ? a:1 : {})

  redraw!
  if type(a:prompt) == v:t_list
    for l:msg in a:prompt[:-2]
      call wiki#ui#echo(l:msg)
    endfor
    let l:prompt = a:prompt[-1]
  else
    let l:prompt = a:prompt
  endif

  return has_key(l:opts, 'completion')
        \ ? input(l:prompt, l:opts.text, l:opts.completion)
        \ : input(l:prompt, l:opts.text)
endfunction

" }}}1
function! wiki#ui#input_quick_from(prompt, choices) abort " {{{1
  while v:true
    redraw!
    if type(a:prompt) == v:t_list
      for l:msg in a:prompt
        call wiki#ui#echo(l:msg)
      endfor
    else
      call wiki#ui#echo(a:prompt)
    endif
    let l:input = nr2char(getchar())

    if index(["\<C-c>", "\<Esc>"], l:input) >= 0
      echon 'aborted!'
      return ''
    endif

    if index(a:choices, l:input) >= 0
      echon l:input
      return l:input
    endif
  endwhile
endfunction

" }}}1

function! wiki#ui#confirm(prompt) abort " {{{1
  if type(a:prompt) != v:t_list
    let l:prompt = [a:prompt]
  else
    let l:prompt = a:prompt
  endif
  let l:prompt[-1] .= ' [y]es/[n]o: '

  return wiki#ui#input_quick_from(l:prompt, ['y', 'n']) ==# 'y'
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

  let [l:index, l:value] = s:choose_from(
        \ type(a:container) == v:t_dict ? values(a:container) : a:container,
        \ l:options)
  sleep 75m
  redraw!

  if l:options.return ==# 'value'
    return l:value
  endif

  if type(a:container) == v:t_dict
    return l:index >= 0 ? keys(a:container)[l:index] : ''
  endif

  return l:index
endfunction

" }}}1

function! s:choose_from(list, options) abort " {{{1
  let l:length = len(a:list)
  let l:digits = len(l:length)
  if l:length == 1 | return [0, a:list[0]] | endif

  " Create the menu
  let l:menu = []
  let l:format = printf('%%%dd', l:digits)
  let l:i = 0
  for l:x in a:list
    let l:i += 1
    call add(l:menu, [
          \ ['ModeMsg', printf(l:format, l:i) . ': '],
          \ type(l:x) == v:t_dict ? l:x.name : l:x
          \])
  endfor
  if a:options.abort
    call add(l:menu, [
          \ ['ModeMsg', repeat(' ', l:digits - 1) . 'x: '],
          \ 'Abort'
          \])
  endif

  " Loop to get a valid choice
  while 1
    redraw!

    call wiki#ui#echo(a:options.prompt)
    for l:line in l:menu
      call wiki#ui#echo(l:line)
    endfor
    call s:echo_clear_buffer()

    try
      let l:choice = s:get_number(l:length, l:digits, a:options.abort)
      if a:options.abort && l:choice == -2
        return [-1, '']
      endif

      if l:choice >= 0 && l:choice < len(a:list)
        return [l:choice, a:list[l:choice]]
      endif
    endtry
  endwhile
endfunction

" }}}1
function! s:get_number(max, digits, abort) abort " {{{1
  let l:choice = ''
  echo '> '

  while len(l:choice) < a:digits
    if len(l:choice) > 0 && (l:choice . '0') > a:max
      return l:choice - 1
    endif

    let l:input = nr2char(getchar())

    if a:abort && l:input ==# 'x'
      echon l:input
      return -2
    endif

    if len(l:choice) > 0 && l:input ==# "\<cr>"
      return l:choice - 1
    endif

    if l:input !~# '\d' | continue | endif

    if (l:choice . l:input) > 0
      let l:choice .= l:input
      echon l:input
    endif
  endwhile

  return l:choice - 1
endfunction

" }}}1
