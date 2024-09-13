" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#utils#add_extension(filename) abort " {{{1
  " Input: Filename with possibly missing file extension
  " Output: Filename with resolved extension

  " Collect extension candidates
  let l:extensions = wiki#u#uniq_unsorted(g:wiki_filetypes
        \ + (exists('b:wiki.extension') ? [b:wiki.extension] : []))

  if index(l:extensions, fnamemodify(a:filename, ':e')) >= 0
    return a:filename
  endif

  " Determine the proper extension (if necessary)
  for l:ext in l:extensions
    let l:newpath = a:filename . '.' . l:ext
    if filereadable(l:newpath) | return l:newpath | endif
  endfor

  " Fallback
  return a:filename . '.' . l:extensions[0]
endfunction

" }}}1
function! wiki#url#utils#extract_anchor(stripped) abort " {{{1
  let l:parts = split(a:stripped, '#', 1)

  return len(l:parts) > 1
        \ ? substitute(join(l:parts[1:], '#'), '#$', '', '')
        \ : ''
endfunction

" }}}1
function! wiki#url#utils#resolve_path(filename, origin) abort " {{{1
  let l:filename = a:filename
  if l:filename =~# '/$'
    let l:filename .= get(get(b:, 'wiki', {}), 'index_name', '')
  endif

  " Link within same page has empty filename
  if empty(l:filename) | return a:origin | endif

  let l:path = l:filename[0] ==# '/'
        \ ? wiki#get_root() . l:filename
        \ : (empty(a:origin)
        \   ? wiki#get_root()
        \   : fnamemodify(a:origin, ':p:h')) . '/' . l:filename
  let l:path = wiki#paths#s(l:path)

  return wiki#url#utils#add_extension(l:path)
endfunction

" }}}1

function! wiki#url#utils#go_to_file(path, edit_cmd, url_stripped, do_edit) abort " {{{1
  if !a:do_edit | return | endif

  " Check if dir exists
  let l:dir = fnamemodify(a:path, ':p:h')
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif

  try
    execute a:edit_cmd fnameescape(a:path)
  catch /E325:/
  endtry

  let b:wiki = get(b:, 'wiki', {})

  if !filereadable(a:path)
    redraw!
    call wiki#log#info('Opened new page "' . a:url_stripped . '"')
  end
endfunction

" }}}1
function! wiki#url#utils#go_to_anchor_adoc(anchor, do_edit) abort " {{{1
  if empty(a:anchor) | return | endif

  " Manually add position to jumplist (necessary if we're in same file)
  if !a:do_edit
    normal! m'
  endif

  let l:match = matchlist(a:anchor, '\(.*\)[- _]\(\d\+\)$')
  if empty(l:match)
    let l:re = a:anchor
    let l:num = 1
  else
    let l:re = l:match[1]
    let l:num = l:match[2]
  endif

  let l:re = substitute(l:re, '^_', '', '')
  let l:re = substitute(l:re, '[- _]', '[- _]', 'g')
  let l:re = '\c^=\{1,6}\s*' . l:re

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
function! wiki#url#utils#go_to_anchor_wiki(anchor, do_edit) abort " {{{1
  if empty(a:anchor) | return | endif

  " Manually add position to jumplist (necessary if we're in same file)
  if !a:do_edit
    normal! m'
  endif

  let l:old_pos = getcurpos('.')
  call cursor(1, 1)


  "for l:part in split(a:anchor, '#', 0)
  "  let l:notag = l:part
  "  let l:part = substitute(l:part, '[- ]', '[- ]', 'g')
  "  let l:header = '^\c#\{1,6}\s*' . l:part . '\s*$'
  "  let l:headerid = '^#\{1,6}\s*\w.*\s{#' . l:notag . '}\s*$'
  "  let l:bold = wiki#rx#surrounded(l:part, '*')
  "
  "  if !(search(l:header, 'Wc') || search(l:bold, 'Wc') || search(l:headerid, 'Wc'))
  "    call setpos('.', l:old_pos)
  "    break
  "  endif
  "  let l:old_pos = getcurpos('.')
  "endfor

  "" Potential fix for issues
  for l:part in split(a:anchor, '#', 0)
    let l:notag = l:part
    let l:part = substitute(l:part, '[- ]', '[- ]', 'g')
    let l:header = '^\c#\{1,6}\s*' . l:part . '\s*$'
    let l:headerid = '^#\{1,6}\s*\w.*\s{#' . l:notag . '}\s*$'
    let l:bold = wiki#rx#surrounded(l:part, '*')

    if !(search(l:headerid, 'Wc'))
      call setpos('.', l:old_pos)
      break
    elif !(search(l:header, 'Wc') || search(l:bold, 'Wc'))
      call setpos('.', l:old_pos)
      break
    endif
    let l:old_pos = getcurpos('.')
  endfor


endfunction

" }}}1
function! wiki#url#utils#focus(do_edit) abort " {{{1
  if !&foldenable | return | endif

  if a:do_edit
    normal! zx
  else
    normal! zv
  endif
endfunction

" }}}1

function! wiki#url#utils#url_encode(str) abort " {{{1
  " This code is based on Tip Pope's vim-unimpaired:
  " https://github.com/tpope/vim-unimpaired
  return substitute(
        \ iconv(a:str, 'latin1', 'utf-8'),
        \ '[^A-Za-z0-9_.~-]',
        \ '\="%".printf("%02X",char2nr(submatch(0)))',
        \ 'g'
        \)
endfunction

" }}}1
function! wiki#url#utils#url_decode(str) abort " {{{1
  " This code is based on Tip Pope's vim-unimpaired:
  " https://github.com/tpope/vim-unimpaired
  let l:str =
        \ substitute(
        \   substitute(
        \     substitute(a:str, '%0[Aa]\n$', '%0A', ''),
        \     '%0[Aa]', '\n', 'g'),
        \   '+', ' ', 'g')
  let l:str = substitute(l:str, '%\(\x\x\)', '\=nr2char("0x".submatch(1))', 'g')
  return iconv(str, 'utf-8', 'latin1')
endfunction

" }}}1
