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
function! wiki#ui#legacy#select(prompt, list) abort " {{{1
  if empty(a:list) | return [-1, ''] | endif

  let l:length = len(a:list)
  let l:digits = len(l:length)
  if l:length == 1 | return [0, a:list[0]] | endif

  " Use simple menu when in operator mode
  if !empty(&operatorfunc)
    let l:choices = map(deepcopy(a:list), { i, x -> (i+1) . ': ' . x })
    let l:choice = inputlist(l:choices) - 1
    sleep 75m
    redraw!
    return l:choice >= 0 && l:choice < l:length
          \ ? [l:choice, a:list[l:choice]]
          \ : [-1, '']
  endif

  " Create the menu
  let l:menu = [a:prompt]
  let l:format = printf('%%%dd', l:digits)
  let l:i = 0
  for l:x in a:list
    let l:i += 1
    call add(l:menu, [
          \ ['ModeMsg', printf(l:format, l:i) . ': '],
          \ type(l:x) == v:t_dict ? l:x.name : l:x
          \])
  endfor
  call add(l:menu, [
        \ ['ModeMsg', repeat(' ', l:digits - 1) . 'x: '],
        \ 'Abort'
        \])

  " Loop to get a valid choice
  while v:true
    redraw!

    for l:line in l:menu
      call wiki#ui#echo(l:line)
    endfor

    try
      let l:choice = wiki#ui#get_number(l:length, l:digits, v:true)
      if l:choice == -2
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
