" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#adoc#parse(url) abort " {{{1
  let l:parts = split(a:url.stripped, '#', 1)
  let l:url = deepcopy(s:parser)

  " Extract path and anchor/ID
  if len(l:parts) == 1
    let l:url.path = ''
    let l:url.anchor = l:parts[0]
  else
    let l:root = empty(a:url.origin)
          \ ? wiki#get_root()
          \ : fnamemodify(a:url.origin, ':p:h')
    let l:url.path = simplify(printf('%s/%s', l:root, l:parts[0]))
    let l:url.dir = fnamemodify(l:url.path, ':p:h')
    let l:url.anchor = l:parts[1]
  endif

  return l:url
endfunction

" }}}1

let s:parser = {}
function! s:parser.open(...) abort dict " {{{1
  let l:cmd = a:0 > 0 ? a:1 : 'edit'

  " Open wiki file
  let l:same_file = resolve(self.path) ==# resolve(expand('%:p'))
  if !l:same_file
    " Check if dir exists
    let l:dir = fnamemodify(self.path, ':p:h')
    if !isdirectory(l:dir)
      call mkdir(l:dir, 'p')
    endif

    if !empty(self.origin)
          \ && resolve(self.origin) ==# resolve(expand('%:p'))
      let l:old_position = [expand('%:p'), getpos('.')]
    elseif &filetype ==# 'wiki'
      let l:old_position = [self.origin, []]
    endif

    execute l:cmd fnameescape(self.path)

    if exists('l:old_position')
      let b:wiki = get(b:, 'wiki', {})
      call wiki#nav#add_to_stack(l:old_position)
    endif
  endif

  " Go to anchor
  if !empty(self.anchor)
    " Manually add position to jumplist (necessary if we're in the same file)
    if l:same_file
      normal! m'
    endif

    call self.open_anchor()
  endif

  " Focus
  if &foldenable
    if l:same_file
      normal! zv
    else
      normal! zx
    endif
  endif

  if exists('#User#WikiLinkOpened')
    doautocmd <nomodeline> User WikiLinkOpened
  endif
endfunction

"}}}1
function! s:parser.open_anchor() abort dict " {{{1
  let l:match = matchlist(self.anchor, '\(.*\)[- _]\(\d\+\)$')
  if empty(l:match)
    let l:re = self.anchor
    let l:num = 1
  else
    let l:re = l:match[1]
    let l:num = l:match[2]
  endif

  let l:re = substitute(l:re, '^_', '', '')
  let l:re = substitute(l:re, '[- _]', '[- _]', 'g')
  let l:re = '\C^=\{1,6}\s*' . l:re

  let l:old_pos = getpos('.')
  call cursor(1, 1)

  for l:_ in range(l:num)
    if !search(l:re, l:_ == 0 ? 'Wc' : 'W')
      call setpos('.', l:old_pos)
      break
    endif
    let l:old_pos = getpos('.')
  endfor
endfunction

" }}}1
