" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#log#echo(input, ...) abort " {{{1
  let l:opts = extend({'indent': 0}, a:0 > 0 ? a:1 : {})

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
function! wiki#log#clear_buffer() abort " {{{1
  if empty(s:buffer) | return | endif
  let l:cmdheight = &cmdheight
  let &cmdheight = len(s:buffer) + 2

  echo repeat('-', winwidth(0)-1) . "\n" . join(s:buffer, "\n")
  let s:buffer = []

  let &cmdheight = l:cmdheight
endfunction

" }}}1

function! s:echo_string(msg, opts) abort " {{{1
  let l:msg = repeat(' ', a:opts.indent) . a:msg

  if g:wiki#log#buffered
    call add(s:buffer, l:msg)
  else
    echo l:msg
  endif
endfunction

let g:wiki#log#buffered = get(g:, 'wiki#log#buffered', v:false)
let s:buffer = []

" }}}1
function! s:echo_formatted(parts, opts) abort " {{{1
  if g:wiki#log#buffered
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


function! wiki#log#info(...) abort " {{{1
  call s:logger.add(a:000, 'info')
endfunction

" }}}1
function! wiki#log#warn(...) abort " {{{1
  call s:logger.add(a:000, 'warning')
endfunction

" }}}1
function! wiki#log#error(...) abort " {{{1
  call s:logger.add(a:000, 'error')
endfunction

" }}}1


let s:logger = {
      \ 'entries' : [],
      \ 'type_to_highlight' : {
      \   'info' : 'Identifier',
      \   'warning' : 'WarningMsg',
      \   'error' : 'ErrorMsg',
      \ },
      \}
function! s:logger.add(messages, type) abort dict " {{{1
  let l:entry = {}
  let l:entry.type = a:type
  let l:entry.time = strftime('%T')
  let l:entry.callstack = wiki#debug#stacktrace()[1:]
  let l:entry.msg = a:messages
  call add(self.entries, l:entry)

  call wiki#log#echo([
        \ [self.type_to_highlight[a:type], 'wiki: '],
        \ a:messages[0]
        \])
  for l:msg in a:messages[1:]
    call wiki#log#echo(l:msg, {'indent': 2})
  endfor
endfunction

" }}}1
