" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#url#wiki#parse(url) abort " {{{1
  let l:url = deepcopy(s:parser)

  " Extract anchor
  let l:anchors = split(a:url.stripped, '#', 1)
  let l:url.anchor = len(l:anchors) > 1 && !empty(l:anchors[-1])
        \ ? join(l:anchors[1:], '#') : ''

  " Parse the file path relative to wiki root
  if empty(l:anchors[0])
    let l:fname = fnamemodify(a:url.origin, ':p:t:r')
  else
    let l:fname = l:anchors[0]
          \ . (l:anchors[0] =~# '/$' ? b:wiki.index_name : '')
  endif

  " Determine the proper extension (if necessary)
  if empty(fnamemodify(l:fname, ':e'))
    let l:fname .= '.' . (exists('b:wiki.extension')
          \ ? b:wiki.extension
          \ : g:wiki_filetypes[0])
  endif

  " Extract the full path
  let l:url.path = l:fname[0] ==# '/'
        \ ? wiki#buffer#get_root() . '/' . l:fname
        \ : fnamemodify(a:url.origin, ':p:h') . '/' . l:fname
  let l:url.dir = fnamemodify(l:url.path, ':p:h')

  return l:url
endfunction

" }}}1

let s:parser = {}
function! s:parser.open(...) abort dict " {{{1
  let l:cmd = a:0 > 0 ? a:1 : 'edit'

  " Check if dir exists
  let l:dir = fnamemodify(self.path, ':p:h')
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif

  " Open wiki file
  let l:same_file = resolve(self.path) ==# resolve(expand('%:p'))
  if !l:same_file
    if !empty(self.origin)
          \ && resolve(self.origin) ==# resolve(expand('%:p'))
      let l:prev_link = [expand('%:p'), getpos('.')]
    elseif &filetype ==# 'wiki'
      let l:prev_link = [self.origin, []]
    endif

    execute l:cmd fnameescape(self.path)

    if exists('l:prev_link')
      let b:wiki = extend(get(b:, 'wiki', {}),
            \ { 'prev_link' : l:prev_link }, 'force')
    endif
  endif

  " Go to anchor
  if !empty(self.anchor)
    " Manually add position to jumplist (necessary if we in same file)
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
      normal! zMzv
    endif
  endif
  normal! zz
endfunction

"}}}1
function! s:parser.open_anchor() abort dict " {{{1
  let l:old_pos = getpos('.')
  call cursor(1, 1)

  for l:part in split(self.anchor, '#', 0)
    let l:header = '^#\{1,6}\s*' . l:part . '\s*$'
    let l:bold = wiki#rx#surrounded(l:part, '*')

    if !(search(l:header, 'Wc') || search(l:bold, 'Wc'))
      call setpos('.', l:old_pos)
      break
    endif
    let l:old_pos = getpos('.')
  endfor
endfunction

" }}}1

