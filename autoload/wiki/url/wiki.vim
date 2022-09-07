" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#wiki#handler(url) abort " {{{1
  let l:handler = deepcopy(s:handler)
  let l:handler.stripped = a:url.stripped
  let l:handler.origin = a:url.origin

  " Extract the anchor
  let l:anchors = split(a:url.stripped, '#', 1)
  let l:handler.anchor = len(l:anchors) > 1 ? join(l:anchors[1:], '#') : ''
  let l:handler.anchor = substitute(l:handler.anchor, '#$', '', '')

  " Extract the target filename
  let l:fname = l:anchors[0]
  if l:fname =~# '/$'
    let l:fname .= get(get(b:, 'wiki', {}), 'index_name', '')
  endif

  let l:handler.path = call(g:wiki_resolver, [l:fname, a:url.origin])
  let l:handler.dir = fnamemodify(l:handler.path, ':p:h')

  return l:handler
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
  let l:path = wiki#paths#s(l:path)

  " Collect extension candidates
  let l:extensions = wiki#u#uniq_unsorted(g:wiki_filetypes
        \ + (exists('b:wiki.extension') ? [b:wiki.extension] : []))
  if index(l:extensions, fnamemodify(l:path, ':e')) >= 0
    return l:path
  endif

  " Determine the proper extension (if necessary)
  for l:ext in l:extensions
    let l:newpath = l:path . '.' . l:ext
    if filereadable(l:newpath) | return l:newpath | endif
  endfor

  return l:path . '.' . l:extensions[0]
endfunction

" }}}1


let s:handler = {}
function! s:handler.follow(...) abort dict " {{{1
  if a:0 > 1
    let l:cmd = a:2 . ' ' . a:1
  elseif a:0 == 1
    let l:cmd = a:1
  else
    let l:cmd = 'edit'
  endif

  " Check if dir exists
  let l:dir = fnamemodify(self.path, ':p:h')
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif

  " Open wiki file
  let l:same_file = resolve(self.path) ==# resolve(expand('%:p'))
  if !l:same_file
    if !empty(expand('%'))
      let l:origin = deepcopy(self)
      let l:origin.curpos = getcurpos()
      call wiki#nav#add_to_stack(l:origin)
    endif

    try
      execute l:cmd fnameescape(self.path)
    catch /E325:/
    endtry

    let b:wiki = get(b:, 'wiki', {})

    if !filereadable(self.path)
      redraw!
      call wiki#log#info('Opened new page "' . self.stripped . '"')
    end
  endif

  " Go to anchor
  if !empty(self.anchor)
    " Manually add position to jumplist (necessary if we're in same file)
    if l:same_file
      normal! m'
    endif

    call self.follow_anchor()
  endif

  " Focus
  if &foldenable
    if l:same_file
      normal! zv
    else
      normal! zx
    endif
  endif

  if exists('#User#WikiLinkFollowed')
    doautocmd <nomodeline> User WikiLinkFollowed
  endif
endfunction

"}}}1
function! s:handler.follow_anchor() abort dict " {{{1
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
