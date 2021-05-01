" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#wiki#parse(url) abort " {{{1
  let l:url = deepcopy(s:parser)

  " Extract the anchor
  let l:anchors = split(a:url.stripped, '#', 1)
  let l:url.anchor = len(l:anchors) > 1 ? join(l:anchors[1:], '#') : ''
  let l:url.anchor = substitute(l:url.anchor, '#$', '', '')

  " Extract the target filename
  let l:fname = l:anchors[0]
  if l:fname =~# '/$'
    let l:fname .= get(get(b:, 'wiki', {}), 'index_name', '')
  endif

  let l:url.path = call(g:wiki_resolver, [l:fname, a:url.origin])
  let l:url.dir = fnamemodify(l:url.path, ':p:h')

  return l:url
endfunction

" }}}1
function! wiki#url#wiki#resolver(fname, origin) abort " {{{1
  if empty(a:fname) | return a:origin | endif

  " Extract the full path
  let l:path = a:fname[0] ==# '/'
        \ ? wiki#get_root() . a:fname
        \ : (empty(a:origin)
        \   ? wiki#get_root()
        \   : fnamemodify(a:origin, ':p:h')) . '/' . a:fname
  let l:path = simplify(l:path)

  " Determine the proper extension (if necessary)
  let l:extensions = wiki#u#uniq_unsorted(
        \ (exists('b:wiki.extension') ? [b:wiki.extension] : [])
        \ + g:wiki_filetypes)
  if index(l:extensions, fnamemodify(a:fname, ':e')) < 0
    let l:path = l:path
    let l:path .= '.' . l:extensions[0]

    if !filereadable(l:path) && len(l:extensions) > 1
      for l:ext in l:extensions[1:]
        let l:newpath = l:path . '.' . l:ext
        if filereadable(l:newpath)
          let l:path = l:newpath
          break
        endif
      endfor
    endif
  endif

  return l:path
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
      normal! zx
    endif
  endif

  if exists('#User#WikiLinkOpened')
    doautocmd <nomodeline> User WikiLinkOpened
  endif
endfunction

"}}}1
function! s:parser.open_anchor() abort dict " {{{1
  let l:old_pos = getpos('.')
  call cursor(1, 1)

  for l:part in split(self.anchor, '#', 0)
    let l:part = substitute(l:part, '[- ]', '[- ]', 'g')
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
