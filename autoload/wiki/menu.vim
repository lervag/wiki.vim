" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#menu#choose(list, ...) abort " {{{1
  let l:opts = a:0 > 0 ? a:1 : {}

  " Create menu
  let l:frmt = '%' . (3 + strlen(string(len(a:list)))) . 's'
  let l:list_menu = []
  for l:i in range(len(a:list))
    let l:list_menu += [['[' . (l:i + 1) . '] ', a:list[l:i]]]
  endfor
  let l:list_menu += [['[x] ', 'Abort']]

  " Ask for user input to choose desired candidate
  while 1
    redraw

    " Print menu
    if get(l:opts, 'fancy', 1)
      if has_key(l:opts, 'header')
        echohl Title
        echo 'wiki: '
        echohl NONE
        echon l:opts.header
      endif

      for [l:key, l:val] in l:list_menu
        echohl ModeMsg
        echo printf(l:frmt, l:key)
        echohl NONE
        echon l:val
      endfor
    else
      echo join(map(copy(l:list_menu), 'v:val[0] . v:val[1]'), "\n")
    endif

    if len(a:list) > 9
      let l:choice = input('> ')
    else
      let l:choice = nr2char(getchar())
    endif
    if l:choice ==# 'x'
      redraw!
      return -1
    endif

    let l:index = str2nr(l:choice)
    if l:index > 0 && l:index <= len(a:list)
      redraw!
      return l:index - 1
    endif
  endwhile
endfunction

" }}}1
