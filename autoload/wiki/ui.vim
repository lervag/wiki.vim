" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

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
  echohl ModeMsg
  echo a:message
  echohl None
endfunction

" }}}1
function! wiki#ui#echof(parts) abort " {{{1
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

function! s:choose_from(list, options) abort " {{{1
  if len(a:list) == 1 | return a:list[0] | endif

  " TODO: Fiks menu with op.mapping
  " " Print the menu; fancy printing is not possible with operator mapping
  " if exists('wiki#link#word#operator')
  "   echo join(map(copy(l:list_menu), 'v:val[0] . v:val[1]'), "\n")

  while 1
    redraw!

    unsilent call wiki#ui#echo(a:options.prompt)

    let l:choices = 0
    if a:options.abort
      unsilent call wiki#ui#echof([['Warning', '0'], ': Abort'])
    endif
    for l:x in a:list
      let l:choices += 1
      unsilent call wiki#ui#echof(
            \ [['Warning', l:choices], ': ',
            \  type(l:x) == v:t_dict ? l:x.name : l:x]
            \)
    endfor

    try
      let l:choice = l:choices > 9
              \ ? s:_get_choice_many()
              \ : s:_get_choice_few()

      if a:options.abort && l:choice == 0
        return -1
      endif

      let l:choice -= 1
      if l:choice >= 0 && l:choice < len(a:list)
        return l:choice
      endif
    endtry
  endwhile
endfunction

" }}}1

function! s:_get_choice_few() abort " {{{1
  echo '> '
  let l:choice = nr2char(getchar())
  echon l:choice
  return l:choice
endfunction

" }}}1
function! s:_get_choice_many() abort " {{{1
  return str2nr(input('> '))
endfunction

" }}}1
