" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

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

function! wiki#log#get() abort " {{{1
  return s:logger.entries
endfunction

" }}}1

function! wiki#log#open() abort " {{{1
  call wiki#scratch#new(s:logger)
endfunction

" }}}1

function! wiki#log#toggle_verbose() abort " {{{1
  let s:logger.verbose = !s:logger.verbose
endfunction

" }}}1
function! wiki#log#set_silent() abort " {{{1
  let s:logger.verbose_old = get(s:logger, 'verbose_old', s:logger.verbose)
  let s:logger.verbose = 0
endfunction

" }}}1
function! wiki#log#set_silent_restore() abort " {{{1
  let s:logger.verbose = get(s:logger, 'verbose_old', s:logger.verbose)
endfunction

" }}}1


let s:logger = {
      \ 'name': 'WikiMessageLog',
      \ 'entries' : [],
      \ 'type_to_highlight' : {
      \   'info' : 'Identifier',
      \   'warning' : 'WarningMsg',
      \   'error' : 'ErrorMsg',
      \ },
      \ 'type_to_level': {
      \   'info': 1,
      \   'warning': 2,
      \   'error': 3,
      \ },
      \ 'verbose': get(get(s:, 'logger', {}), 'verbose',
      \                get(g:, 'wiki_log_verbose', 1)),
      \}
function! s:logger.add(msg_arg, type) abort dict " {{{1
  let l:msg_list = []
  for l:msg in a:msg_arg
    if type(l:msg) == v:t_string
      call add(l:msg_list, l:msg)
    elseif type(l:msg) == v:t_list
      call extend(l:msg_list, filter(l:msg, 'type(v:val) == v:t_string'))
    endif
  endfor

  let l:entry = {}
  let l:entry.type = a:type
  let l:entry.time = strftime('%T')
  let l:entry.msg = l:msg_list
  let l:entry.callstack = wiki#debug#stacktrace()[1:]
  for l:level in l:entry.callstack
    let l:level.nr -= 2
  endfor
  call add(self.entries, l:entry)

  if self.verbose
    if self.type_to_level[a:type] > 1
      unsilent call self.notify(l:msg_list, a:type)
    else
      call self.notify(l:msg_list, a:type)
    endif
  endif
endfunction

" }}}1
function! s:logger.notify(msg_list, type) abort dict " {{{1
  call wiki#ui#echo([
        \ [self.type_to_highlight[a:type], 'wiki:'],
        \ ' ' . a:msg_list[0]
        \])
  for l:msg in a:msg_list[1:]
    call wiki#ui#echo(l:msg, {'indent': 2})
  endfor
endfunction

" }}}1
function! s:logger.print_content() abort dict " {{{1
  for l:entry in self.entries
    call append('$', printf('%s: %s', l:entry.time, l:entry.type))
    for l:stack in l:entry.callstack
      if l:stack.lnum > 0
        call append('$', printf('  #%d %s:%d', l:stack.nr, l:stack.filename, l:stack.lnum))
      else
        call append('$', printf('  #%d %s', l:stack.nr, l:stack.filename))
      endif
      call append('$', printf('  In %s', l:stack.function))
      if !empty(l:stack.text)
        call append('$', printf('    %s', l:stack.text))
      endif
    endfor
    for l:msg in l:entry.msg
      call append('$', printf('  %s', l:msg))
    endfor
    call append('$', '')
  endfor
endfunction

" }}}1
function! s:logger.syntax() abort dict " {{{1
  syntax match WikiLogOther /.*/

  syntax include @VIM syntax/vim.vim
  syntax match WikiLogVimCode /^    .*/ transparent contains=@VIM

  syntax match WikiLogKey /^\S*:/ nextgroup=WikiLogValue
  syntax match WikiLogKey /^  #\d\+/ nextgroup=WikiLogValue
  syntax match WikiLogKey /^  In/ nextgroup=WikiLogValue
  syntax match WikiLogValue /.*/ contained
endfunction

" }}}1
