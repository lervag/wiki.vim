" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#ui#legacy#confirm(prompt) abort " {{{1
  let l:prompt = type(a:prompt) == v:t_list ? a:prompt : [a:prompt]
  let l:prompt[-1] .= ' [y]es/[n]o: '

  while v:true
    redraw!
    for l:part in l:prompt
      call wiki#ui#echo(l:part)
    endfor

    let l:input = nr2char(getchar())
    if index(["\<C-c>", "\<Esc>", 'y', 'Y', 'n', 'N'], l:input) >= 0
      break
    endif
  endwhile

  return l:input ==? 'y'
endfunction

" }}}1
function! wiki#ui#legacy#input(options) abort " {{{1
  if !empty(a:options.info)
    redraw!
    call wiki#ui#echo(a:options.info)
  endif

  let l:input = has_key(a:options, 'completion')
        \ ? input(a:options.prompt, a:options.text, a:options.completion)
        \ : input(a:options.prompt, a:options.text)
  sleep 75m
  redraw!

  return l:input
endfunction

" }}}1
function! wiki#ui#legacy#select(list, options) abort " {{{1
  let l:length = len(a:list)
  let l:digits = len(l:length)
  if l:length == 1 | return [0, a:list[0]] | endif

  " Use simple menu for buffered output
  if g:wiki#ui#buffered
    let l:choices = map(deepcopy(a:list), { i, x -> (i+1) . ': ' . x })
    let l:choice = inputlist(l:choices) - 1
    sleep 75m
    redraw!
    return l:choice >= 0 && l:choice < l:length
          \ ? [l:choice, a:list[l:choice]]
          \ : [-1, '']
  endif

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
  while v:true
    redraw!

    call wiki#ui#echo(a:options.prompt)
    for l:line in l:menu
      call wiki#ui#echo(l:line)
    endfor
    call wiki#ui#clear_buffer()

    try
      let l:choice = s:get_number(l:length, l:digits, a:options.abort)
      if a:options.abort && l:choice == -2
        sleep 75m
        redraw!
        return [-1, '']
      endif

      if l:choice >= 0 && l:choice < l:length
        sleep 75m
        redraw!
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
