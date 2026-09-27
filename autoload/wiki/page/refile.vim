" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#page#refile#default_opts() abort " {{{1
  return #{
        \ target_page: '',
        \ target_anchor: '',
        \ target_relation: '',
        \ target_lnum: -1,
        \}
endfunction

" }}}1
function! wiki#page#refile#parse_args(args) abort " {{{1
  " Arguments:
  "   args: list of command line arguments
  " Returns:
  "   opts: see wiki#page#refile#default_opts()

  let l:opts = wiki#page#refile#default_opts()

  let l:args = copy(a:args)
  while !empty(l:args)
    let l:arg = remove(l:args, 0)

    let l:key = get(s:arg_to_key, l:arg, '')
    if empty(l:key)
      throw printf(
            \ 'wiki.vim: WikiPageRefile argument "%s" not recognized!', l:arg)
    endif

    if empty(l:args)
      throw printf('wiki.vim: Missing value for "%s"!', l:arg)
    endif

    let l:value = remove(l:args, 0)
    let l:opts[l:key] = l:key ==# 'target_lnum' ? str2nr(l:value) : l:value
  endwhile

  return l:opts
endfunction

let s:arg_to_key = {
      \ '-page': 'target_page',
      \ '-anchor': 'target_anchor',
      \ '-relation': 'target_relation',
      \ '-lnum': 'target_lnum',
      \}

" }}}1
function! wiki#page#refile#validate_opts(opts) abort " {{{1
  if a:opts.target_lnum >= 0
        \ && (!empty(a:opts.target_anchor) || !empty(a:opts.target_relation))
    throw 'wiki.vim: Cannot combine -lnum with -anchor or -relation!'
  endif

  if empty(a:opts.target_relation) | return | endif

  if empty(a:opts.target_anchor)
    throw 'wiki.vim: Option -relation requires -anchor!'
  endif

  if index(s:relations, a:opts.target_relation) < 0
    throw 'wiki.vim: Option -relation must be "inside", "before" or "after"!'
  endif
endfunction

let s:relations = ['inside', 'before', 'after']

" }}}1

function! wiki#page#refile#collect_source() abort " {{{1
  " Returns:
  "   source: dict(path, lnum, lnum_end, header, anchor, anchors, level)

  let l:source = wiki#toc#get_section()
  if !empty(l:source)
    let l:source.path = expand('%:p')
  endif

  return l:source
endfunction

" }}}1
function! wiki#page#refile#ask_for_target(opts, source) abort " {{{1
  " Ask the user for a target page and a target section within that page.
  "
  " Returns:
  "   opts: see wiki#page#refile#default_opts(); empty if the user aborted

  let l:page = wiki#ui#input(#{
        \ info: 'Refile to page [empty for current page]:',
        \ completion: 'customlist,wiki#complete#url',
        \})

  let l:path = wiki#u#eval_filename(l:page)
  if !filereadable(l:path)
    throw 'wiki.vim: Target page was not found!'
  endif

  let l:choice = wiki#ui#select(
        \ wiki#page#refile#get_target_choices(l:path, a:source), #{
        \ prompt: 'Refile into section:',
        \ auto_select: v:false,
        \})
  if empty(l:choice) | return {} | endif

  let a:opts.target_page = l:page
  let a:opts.target_anchor = l:choice ==# s:choice_page ? '' : l:choice
  let a:opts.target_relation = empty(a:opts.target_anchor) ? '' : 'inside'

  return a:opts
endfunction

let s:choice_page = '[end of page]'

" }}}1
function! wiki#page#refile#get_target_choices(path, source) abort " {{{1
  " Returns:
  "   The sections of a:path that are valid refile targets, i.e. all sections
  "   except the source section and its subsections

  let l:entries = wiki#toc#gather_entries(#{ path: a:path })
  if a:path ==# a:source.path
    call filter(l:entries,
          \ { _, x -> x.lnum < a:source.lnum || x.lnum > a:source.lnum_end })
  endif

  return [s:choice_page] + map(l:entries, 'v:val.anchor')
endfunction

" }}}1
function! wiki#page#refile#collect_target(opts, source) abort " {{{1
  " Arguments:
  "   opts: see wiki#page#refile#default_opts()
  "   source: see wiki#page#refile#collect_source()
  " Returns:
  "   target: dict(path, lnum, anchor, level, pad_before)

  let l:path = wiki#u#eval_filename(a:opts.target_page)
  if !filereadable(l:path)
    throw 'wiki.vim: Target page was not found!'
  endif

  let l:lines = l:path ==# expand('%:p') ? getline(1, '$') : readfile(l:path)

  if !empty(a:opts.target_anchor)
    let l:target = s:collect_target_by_anchor(l:path, a:opts, a:source)
  elseif a:opts.target_lnum >= 0
    let l:target = s:collect_target_by_lnum(l:path, a:opts.target_lnum, a:source)
  else
    let l:target = s:collect_target_at_end(l:path, l:lines, a:source)
  endif

  " Separate the refiled section from the preceding line
  let l:target.pad_before = l:target.lnum > 0
        \ && !empty(get(l:lines, l:target.lnum - 1, ''))

  return l:target
endfunction

" }}}1
function! wiki#page#refile#check_levels(source, target) abort " {{{1
  " Ensure that the adjusted header levels stay within the valid range.

  let l:delta = a:target.level - a:source.level
  if l:delta <= 0 | return | endif

  let l:max_level = 0
  for l:entry in wiki#toc#gather_entries(#{
        \ lines: getline(a:source.lnum, a:source.lnum_end) })
    let l:max_level = max([l:max_level, l:entry.level])
  endfor

  if l:max_level + l:delta > 6
    throw 'wiki.vim: Refiling would exceed the maximum header level!'
  endif
endfunction

" }}}1
function! wiki#page#refile#move(source, target) abort " {{{1
  " Arguments:
  "   source: see wiki#page#refile#collect_source()
  "   target: see wiki#page#refile#collect_target()

  let l:lines = getline(a:source.lnum, a:source.lnum_end)
  call s:adjust_levels(l:lines, a:target.level - a:source.level)
  if a:target.pad_before
    let l:lines = [''] + l:lines
  endif

  if a:target.path ==# a:source.path
    " Account for the lines that are removed above the target position
    let l:lnum = a:target.lnum >= a:source.lnum
          \ ? a:target.lnum - (a:source.lnum_end - a:source.lnum + 1)
          \ : a:target.lnum

    call deletebufline('', a:source.lnum, a:source.lnum_end)
    call append(l:lnum, l:lines)
    silent write
    return
  endif

  call deletebufline('', a:source.lnum, a:source.lnum_end)
  silent write

  let l:current_bufnr = bufnr('')
  let l:was_loaded = bufloaded(a:target.path)
  keepalt execute 'silent edit' fnameescape(a:target.path)
  call append(a:target.lnum, l:lines)
  silent write
  if !l:was_loaded
    keepalt execute 'bwipeout'
  endif
  keepalt execute 'buffer' l:current_bufnr
endfunction

" }}}1

function! s:collect_target_by_anchor(path, opts, source) abort " {{{1
  let l:relation = empty(a:opts.target_relation)
        \ ? 'inside'
        \ : a:opts.target_relation

  let l:entries = wiki#toc#gather_entries(#{ path: a:path })

  let l:index = -1
  for l:i in range(len(l:entries))
    if l:entries[l:i].anchor ==# a:opts.target_anchor
      let l:index = l:i
      break
    endif
  endfor

  if l:index < 0
    throw 'wiki.vim: Target anchor not recognized!'
  endif
  let l:section = l:entries[l:index]

  if a:path ==# a:source.path
        \ && l:section.lnum >= a:source.lnum
        \ && l:section.lnum <= a:source.lnum_end
    throw 'wiki.vim: Cannot refile a section into itself!'
  endif

  if l:relation ==# 'inside'
    " Place the section as the first subsection of the target section, i.e.
    " below the text that belongs to the target section itself. The next entry
    " is the first subsection if it is at a deeper level.
    let l:next = get(l:entries, l:index + 1, {})
    let l:lnum = !empty(l:next) && l:next.level > l:section.level
          \ ? l:next.lnum - 1
          \ : l:section.lnum_end
    let l:anchors = l:section.anchors + [a:source.header]
  elseif l:relation ==# 'before'
    let l:lnum = l:section.lnum - 1
    let l:anchors = l:section.anchors[:-2] + [a:source.header]
  else
    let l:lnum = l:section.lnum_end
    let l:anchors = l:section.anchors[:-2] + [a:source.header]
  endif

  return #{
        \ path: a:path,
        \ lnum: l:lnum,
        \ anchor: '#' . join(l:anchors, '#'),
        \ level: len(l:anchors),
        \}
endfunction

" }}}1
function! s:collect_target_by_lnum(path, lnum, source) abort " {{{1
  if a:path ==# a:source.path
        \ && a:lnum >= a:source.lnum
        \ && a:lnum < a:source.lnum_end
    throw 'wiki.vim: Cannot refile a section into itself!'
  endif

  " Keep the source level, but promote the section if the target position is
  " not nested deeply enough
  let l:anchors = [a:source.header]
  if a:source.level > 1
    let l:section = wiki#toc#get_section(#{ path: a:path, at_lnum: a:lnum })
    let l:target_anchors = get(l:section, 'anchors', [])
    call extend(l:anchors, l:target_anchors[:a:source.level - 2], 0)
  endif

  return #{
        \ path: a:path,
        \ lnum: a:lnum,
        \ anchor: '#' . join(l:anchors, '#'),
        \ level: len(l:anchors),
        \}
endfunction

" }}}1
function! s:collect_target_at_end(path, lines, source) abort " {{{1
  return #{
        \ path: a:path,
        \ lnum: len(a:lines),
        \ anchor: '#' . a:source.header,
        \ level: 1,
        \}
endfunction

" }}}1
function! s:adjust_levels(lines, delta) abort " {{{1
  " Shift the header level of every section in a:lines by a:delta

  if a:delta == 0 | return | endif

  let l:char = wiki#toc#get_header_char()
  for l:entry in wiki#toc#gather_entries(#{ lines: a:lines })
    let l:index = l:entry.lnum - 1
    let a:lines[l:index] = a:delta > 0
          \ ? repeat(l:char, a:delta) . a:lines[l:index]
          \ : a:lines[l:index][-a:delta :]
  endfor
endfunction

" }}}1
