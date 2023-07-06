" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#ui#nvim#input(options) abort " {{{1
  return wiki#ui#legacy#input(a:options)
endfunction

" }}}1
function! wiki#ui#nvim#confirm(prompt) abort " {{{1
  let l:padding = 1
  let l:pad = repeat(' ', l:padding)

  " Prepare the confirm dialog lines
  let l:lines = type(a:prompt) == v:t_list ? a:prompt : [a:prompt]
  let l:lines += ['']
  let l:lines += ['  y = Yes']
  let l:lines += ['  n = No ']
  call map(l:lines, { _, x -> empty(x) ? x : l:pad . x })
  let l:lines = repeat([''], l:padding) + l:lines

  " Calculate window dimensions
  let l:winheight = winheight(0)
  let l:winwidth = winwidth(0)
  let l:height = len(l:lines) + l:padding
  let l:width = 0
  for l:line in l:lines
    if strdisplaywidth(l:line) > l:width
      let l:width = strdisplaywidth(l:line)
    endif
  endfor
  let l:width += 2*l:padding

  " Create window and buffer
  call nvim_open_win(bufadd(''), v:true, #{
        \ relative: 'win',
        \ row: (l:winheight - l:height)/3,
        \ col: (l:winwidth - l:width)/2,
        \ width: l:width,
        \ height: l:height,
        \ style: "minimal",
        \ noautocmd: v:true,
        \})
  setlocal buftype=nofile
  call nvim_buf_set_lines(0, 0, -1, v:false, l:lines)

  " Apply some simple highlighting
  syntax match ConfirmPrompt ".*" contains=ConfirmHelp
  syntax match ConfirmHelp   "[yn] = \(Yes\|No\)" contains=ConfirmKey
  syntax match ConfirmKey    "[yn]\ze ="
  highlight link ConfirmPrompt Statement
  highlight link ConfirmHelp Comment
  highlight link ConfirmKey Title
  redraw!

  " Wait for input
  while v:true
    let l:input = nr2char(getchar())
    if index(["\<C-c>", "\<Esc>", 'y', 'Y', 'n', 'N'], l:input) >= 0
      break
    endif
  endwhile

  " Close and return confirmation result
  close
  return l:input ==? 'y'
endfunction

" }}}1
function! wiki#ui#nvim#select(list, options) abort " {{{1
  return wiki#ui#legacy#select(a:list, a:options)
endfunction

" }}}1
