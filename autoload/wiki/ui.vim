" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let g:wiki#ui#buffered = get(g:, 'wiki#ui#buffered', v:false)
let s:buffer = []


function! wiki#ui#choose(container, ...) abort " {{{1
  if empty(a:container) | return '' | endif

  if type(a:container) == v:t_dict
    let l:choose_list = values(a:container)
    let l:return_list = keys(a:container)
  else
    let l:choose_list = a:container
    let l:return_list = a:container
  endif

  let l:options = extend(
        \ {
        \   'prompt': 'Please choose item:',
        \   'abort': v:true,
        \ },
        \ a:0 > 0 ? a:1 : {})

  let l:index = s:choose_from(l:choose_list, l:options)

  sleep 50m
  redraw!

  return l:index < 0 ? '' : l:return_list[l:index]
endfunction

" }}}1
function! wiki#ui#echo(message) abort " {{{1
  if g:wiki#ui#buffered
    call add(s:buffer, a:message)
  else
    echohl ModeMsg
    echo a:message
    echohl None
  endif
endfunction

" }}}1
function! wiki#ui#echof(parts) abort " {{{1
  if g:wiki#ui#buffered
    let l:message = ''
    for l:part in a:parts
      let l:message .= type(l:part) == v:t_list ? l:part[1] : l:part
    endfor
    call add(s:buffer, l:message)
    return
  endif

  echo ''
  try
    for l:part in a:parts
      if type(l:part) == v:t_string
        echohl ModeMsg
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
function! wiki#ui#clear_buffer() abort " {{{1
  let l:cmdheight = &cmdheight
  let &cmdheight = len(s:buffer) + 2

  echo repeat('-', winwidth(0)-1) . "\n" . join(s:buffer, "\n")
  let s:buffer = []

  let &cmdheight = l:cmdheight
endfunction

" }}}1

function! s:choose_from(list, options) abort " {{{1
  let l:length = len(a:list)
  let l:digits = len(l:length)
  if l:length == 1 | return a:list[0] | endif

  " Create the menu
  let l:menu = []
  let l:format = printf('%%%dd', l:digits)
  let l:i = 0
  for l:x in a:list
    let l:i += 1
    call add(l:menu, [
          \ ['Warning', printf(l:format, l:i)],
          \ ': ',
          \ type(l:x) == v:t_dict ? l:x.name : l:x
          \])
  endfor
  if a:options.abort
    call add(l:menu, [
          \ ['Warning', repeat(' ', l:digits - 1) . 'x'],
          \ ': Abort'
          \])
  endif

  " Loop to get a valid choice
  while 1
    redraw!

    call wiki#ui#echo(a:options.prompt)
    for l:line in l:menu
      call wiki#ui#echof(l:line)
    endfor
    call wiki#ui#clear_buffer()

    try
      let l:choice = s:get_number(l:length, l:digits, a:options.abort)
      if a:options.abort && l:choice == -2
        return -1
      endif

      if l:choice >= 0 && l:choice < len(a:list)
        return l:choice
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
