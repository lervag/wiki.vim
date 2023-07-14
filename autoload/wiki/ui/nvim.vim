" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#ui#nvim#input(options) abort " {{{1
  if has_key(a:options, 'completion')
    " We can't replicate completion, so let's just fall back.
    return wiki#ui#legacy#input(a:options)
  endif

  let l:content = empty(a:options.info) ? [] : [a:options.info]
  let l:content += [a:options.prompt]
  let l:popup_cfg = {
        \ 'content': l:content,
        \ 'min_width': 0.7,
        \ 'prompt': a:options.prompt,
        \}
  function l:popup_cfg.highlight() abort dict
    syntax match WikiPopupContent ".*" contains=WikiPopupPrompt
    execute 'syntax match WikiPopupPrompt'
          \ '"^\s*' . self.prompt . '"'
          \ 'nextgroup=WikiPopupPromptInput'
    syntax match WikiPopupPromptInput ".*"  contained
  endfunction
  let l:popup = wiki#ui#nvim#popup(l:popup_cfg)

  let l:value = a:options.text
  while v:true
    call nvim_buf_set_lines(0, -2, -1, v:false, [' > ' . l:value])
    redraw!

    let l:input_raw = getchar()
    let l:input = nr2char(l:input_raw)

    if index(["\<c-c>", "\<esc>", "\<c-q>"], l:input) >= 0
      let l:value = ""
      break
    endif

    if l:input ==# "\<cr>"
      break
    endif

    if l:input_raw ==# "\<bs>"
      let l:value = strcharpart(l:value, 0, strchars(l:value) - 1)
    elseif l:input ==# "\<c-u>"
      let l:value = ""
    else
      let l:value .= l:input
    endif
  endwhile

  call l:popup.close()
  return l:value
endfunction

" }}}1
function! wiki#ui#nvim#confirm(prompt) abort " {{{1
  let l:content = type(a:prompt) == v:t_list ? a:prompt : [a:prompt]
  let l:content += ['']
  let l:content += ['  y = Yes']
  let l:content += ['  n = No ']

  let l:popup_cfg = { 'content': l:content }
  function l:popup_cfg.highlight() abort
    syntax match WikiPopupContent ".*" contains=WikiPopupPrompt
    syntax match WikiPopupPrompt "[yn] = \(Yes\|No\)"
          \ contains=WikiPopupPromptInput
    syntax match WikiPopupPromptInput "= \(Yes\|No\)" contained
  endfunction
  let l:popup = wiki#ui#nvim#popup(l:popup_cfg)

  " Wait for input
  while v:true
    let l:input = nr2char(getchar())
    if index(["\<C-c>", "\<Esc>", 'y', 'Y', 'n', 'N'], l:input) >= 0
      break
    endif
  endwhile

  call l:popup.close()
  return l:input ==? 'y'
endfunction

" }}}1
function! wiki#ui#nvim#select(prompt, list) abort " {{{1
  if empty(a:list) | return [-1, ''] | endif

  let l:length = len(a:list)
  if l:length == 1 | return [0, a:list[0]] | endif

  " Prepare menu of choices
  let l:content = [a:prompt, '']
  let l:digits = len(l:length)
  call add(l:content, repeat(' ', l:digits - 1) . 'x: Abort')
  let l:format = printf('%%%dd: %%s', l:digits)
  let l:i = 0
  for l:x in a:list
    let l:i += 1
    call add(l:content, printf(
          \ l:format, l:i, type(l:x) == v:t_dict ? l:x.name : l:x))
  endfor

  " Create popup window
  let l:popup_cfg = {
        \ 'content': l:content,
        \ 'position': 'window',
        \ 'min_width': 0.8,
        \}
  function l:popup_cfg.highlight() abort
    syntax match WikiPopupContent ".*" contains=WikiPopupPrompt
    syntax match WikiPopupPrompt "^\s*\(\d\+\|x\):\s*"
          \ nextgroup=WikiPopupPromptInput
    syntax match WikiPopupPromptInput ".*" contained
  endfunction
  let l:popup = wiki#ui#nvim#popup(l:popup_cfg)

  let l:value = [-1, '']
  while v:true
    try
      let l:choice = s:get_number(l:length, l:digits)
      if l:choice == -2
        break
      endif

      if l:choice >= 0 && l:choice < l:length
        let l:value = [l:choice, a:list[l:choice]]
        break
      endif
    endtry
  endwhile

  call l:popup.close()
  return l:value
endfunction

" }}}1

function! wiki#ui#nvim#popup(cfg) abort " {{{1
  let l:popup = extend({
        \ 'name': 'WikiPopup',
        \ 'content': [],
        \ 'padding': 1,
        \ 'position': 'cursor',
        \ 'min_width': 0.0,
        \ 'min_height': 0.0,
        \}, a:cfg)

  " Prepare content
  let l:content = map(
        \ repeat([''], l:popup.padding) + deepcopy(l:popup.content),
        \ { _, x -> empty(x) ? x : repeat(' ', l:popup.padding) . x }
        \)

  " Calculate window dimensions
  let l:winheight = winheight(0)
  let l:winwidth = winwidth(0)
  let l:height = len(l:content) + l:popup.padding
  let l:height = max([l:height, float2nr(l:popup.min_height*l:winheight)])

  let l:width = 0
  for l:line in l:content
    if strdisplaywidth(l:line) > l:width
      let l:width = strdisplaywidth(l:line)
    endif
  endfor
  let l:width += 2*l:popup.padding
  let l:width = max([l:width, float2nr(l:popup.min_width*l:winwidth)])

  " Create and fill the buffer
  let l:bufnr = bufadd(l:popup.name)
  call nvim_buf_set_lines(l:bufnr, 0, -1, v:false, l:content)
  call nvim_buf_set_option(l:bufnr, 'buftype', 'nofile')

  " Create popup window
  let l:winopts = #{
        \ width: l:width,
        \ height: l:height,
        \ style: "minimal",
        \ noautocmd: v:true,
        \}
  if l:popup.position ==# 'cursor'
    let l:winopts.relative = 'cursor'

    let l:c = col('.')
    if l:width < l:winwidth - l:c - 1
      let l:winopts.row = 1 - l:height/2
      let l:winopts.col = 2
    else
      let l:winopts.row = 1
      let l:winopts.col = 1
      " let l:winopts.col = (l:winwidth - width)/2 - l:c
    endif
  elseif l:popup.position ==# 'window'
    let l:winopts.relative = 'win'
    let l:winopts.row = (l:winheight - l:height)/3
    let l:winopts.col = (l:winwidth - l:width)/2
  endif
  call nvim_open_win(l:bufnr, v:true, l:winopts)

  " Define default highlight groups
  if !hlexists("WikiPopupContent")
    highlight default link WikiPopupContent PreProc
    highlight default link WikiPopupPrompt Special
    highlight default link WikiPopupPromptInput Type
  endif

  " Apply highlighting
  if has_key(l:popup, 'highlight')
    call l:popup.highlight()
  endif

  call extend(l:popup, #{
        \ bufnr: l:bufnr,
        \ height: height,
        \ width: width,
        \})

  function l:popup.close() abort dict
    close
    call nvim_buf_delete(self.bufnr, #{force: v:true})
  endfunction

  redraw!
  return l:popup
endfunction

" }}}1

function! s:get_number(max, digits) abort " {{{1
  let l:choice = ''

  while len(l:choice) < a:digits
    if len(l:choice) > 0 && (l:choice . '0') > a:max
      return l:choice - 1
    endif

    let l:input = nr2char(getchar())

    if l:input ==# 'x'
      return -2
    endif

    if len(l:choice) > 0 && l:input ==# "\<cr>"
      return l:choice - 1
    endif

    if l:input !~# '\d' | continue | endif

    if (l:choice . l:input) > 0
      let l:choice .= l:input
    endif
  endwhile

  return l:choice - 1
endfunction

" }}}1
