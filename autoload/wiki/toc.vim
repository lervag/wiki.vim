" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#toc#create(local) abort " {{{1
  let l:entries = wiki#toc#gather_entries(getline(1, '$'), a:local)
  if empty(l:entries) | return | endif

  if a:local
    let l:level = l:entries[0].level + 1
    let l:lnum_top = l:entries[0].lnum
    if len(l:entries) <= 1 | return | endif
    let l:entries = l:entries[1:]
    let l:lnum_bottom = l:entries[0].lnum
  else
    let l:level = 1
    let l:lnum_top = 1
    let l:lnum_bottom = get(get(l:entries, 1, {}), 'lnum', line('$'))
  endif

  let l:start = max([l:entries[0].lnum, 0])
  let l:header = '*' . g:wiki_toc_title . '*'
  let l:re = printf(
        \ '\v^%(%s %s|\*%s\*)$',
        \ repeat('#', l:level), g:wiki_toc_title, g:wiki_toc_title)

  " Save the window view and syntax setting and disable syntax (makes things
  " much faster)
  let l:winsave = winsaveview()
  let l:syntax = &l:syntax
  setlocal syntax=off

  "
  " Delete TOC if it exists
  "
  for l:lnum in range(l:lnum_top, l:lnum_bottom)
    if getline(l:lnum) =~# l:re
      let l:header = getline(l:lnum)
      let l:start = l:lnum
      let l:end = l:start + (getline(l:lnum+1) =~# '^\s*$' ? 2 : 1)
      while l:end <= l:lnum_bottom && getline(l:end) =~# '^\s*[*-] '
        let l:end += 1
      endwhile

      let l:foldenable = &l:foldenable
      setlocal nofoldenable
      silent execute printf('%d,%ddelete _', l:start, l:end - 1)
      let &l:foldenable = l:foldenable

      break
    endif
  endfor

  "
  " Add updated TOC
  "
  call append(l:start - 1, l:header)
  let l:length = len(l:entries)
  for l:i in range(l:length)
    call append(l:start + l:i, l:entries[l:i].header)
  endfor
  if getline(l:start + l:length + 1) !=# ''
    call append(l:start + l:length, '')
  endif
  if l:header =~# '^#'
    call append(l:start, '')
  endif

  "
  " Restore syntax and view
  "
  let &l:syntax = l:syntax
  call winrestview(l:winsave)
endfunction

" }}}1
function! wiki#toc#gather_entries(lines, local) abort " {{{1
  let l:start = 1
  let l:is_code = v:false
  let l:entry = {}
  let l:entries = []
  let l:local = {}
  let l:anchor_stack = []
  let l:lnum_current = line('.')

  "
  " Gather toc entries
  "
  let l:lnum = 0
  for l:line in a:lines
    let l:lnum += 1

    if l:line =~# '^\s*```'
      let l:is_code = !l:is_code
    endif
    if l:is_code | continue | endif

    " Get line - check for header
    if l:line !~# g:wiki#rx#header | continue | endif

    " Parse current header
    let l:level = len(matchstr(l:line, '^#*'))
    let l:header = matchlist(l:line, g:wiki#rx#header_items)[2]
    if l:header ==# g:wiki_toc_title | continue | endif

    " Update header stack in order to have well defined anchor
    let l:depth = len(l:anchor_stack)
    if l:depth >= l:level
      call remove(l:anchor_stack, l:level-1, l:depth-1)
    endif
    call add(l:anchor_stack, l:header)
    let l:anchor = '#' . join(l:anchor_stack, '#')

    " Start local boundary container
    if empty(l:local) && l:lnum >= l:lnum_current
      let l:local.level = get(l:entry, 'level')
      let l:local.lnum = get(l:entry, 'lnum')
      let l:local.nstart = len(l:entries) - 1
    endif

    " Add the new entry
    let l:entry = {
          \ 'lnum' : l:lnum,
          \ 'level' : l:level,
          \ 'header_text': l:header,
          \ 'header' : repeat(' ', shiftwidth()*(l:level-1))
          \            . '* ' . wiki#link#template(l:anchor, l:header),
          \ 'anchors' : copy(l:anchor_stack),
          \}
    call add(l:entries, l:entry)

    " Set local boundaries
    if !empty(l:local) && !get(l:local, 'done') && l:level <= l:local.level
      let l:local.done = 1
      let l:local.nend = len(l:entries) - 2
    endif
  endfor

  if !has_key(l:local, 'done')
    let l:local.nend = len(l:entries) - 1
  endif

  let l:depth = get(g:, 'wiki_toc_depth', 6)

  if a:local
    let l:entries = l:entries[l:local.nstart : l:local.nend]
    for l:entry in l:entries
      let l:entry.header = strpart(l:entry.header, 2*l:local.level)
    endfor
    let l:depth += l:entries[0].level
  endif

  return filter(l:entries, 'v:val.level <= l:depth')
endfunction

" }}}1
function! wiki#toc#gather_anchors(...) abort " {{{1
  let l:cache = wiki#cache#open('anchors', {
        \ 'local': 1,
        \ 'default': { 'ftime': -1 },
        \})

  let l:filename = wiki#u#eval_filename(a:0 > 0 ? a:1 : '')
  let l:current = l:cache.get(l:filename)
  let l:ftime = getftime(l:filename)
  if l:ftime > l:current.ftime
    let l:cache.modified = 1
    let l:current.ftime = l:ftime
    let l:current.anchors = s:get_anchors(l:filename)
  endif
  call l:cache.write()

  return copy(l:current.anchors)
endfunction

" }}}1

function! s:get_anchors(filename) abort " {{{1
  if !filereadable(a:filename) | return [] | endif

  let anchor_level = ['', '', '', '', '', '', '']
  let anchors = []
  let current_section = ''
  let preblock = 0
  for line in readfile(a:filename)
    " Ignore fenced code blocks
    if line =~# '^\s*```'
      let l:preblock += 1
    endif
    if l:preblock % 2 | continue | endif

    " Parse headers
    let h_match = matchlist(line, g:wiki#rx#header_items)
    if !empty(h_match)
      let lvl = len(h_match[1]) - 1
      let anchor_level[lvl] = h_match[2]

      let current_section = '#' . join(anchor_level[:lvl], '#')
      call add(anchors, current_section)

      continue
    endif

    " Parse bolded text (there can be several in one line)
    let cnt = 0
    while 1
      let cnt += 1
      let text = matchstr(line, g:wiki#rx#bold, 0, cnt)
      if empty(text) | break | endif

      call add(anchors, current_section . '#' . text[1:-2])
    endwhile
  endfor

  return anchors
endfunction

" }}}1
