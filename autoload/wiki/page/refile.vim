" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#page#refile#collect_source(...) abort " {{{1
  " Returns:
  "   source: dict(path, lnum, lnum_end, header, anchor, level)

  let l:source = wiki#toc#get_section()
  if !empty(l:source)
    let l:source.path = expand('%:p')
  endif

  return l:source
endfunction

" }}}1
function! wiki#page#refile#collect_target(opts, source) abort " {{{1
  " Arguments:
  "   opts: dict(
  "     target_page,
  "     target_lnum,
  "     target_anchor_before?,
  "   )
  "   source: dict(path, lnum, lnum_end, header, anchor)
  " Returns:
  "   target: dict(path, lnum, anchor, level)

  let l:path = wiki#u#eval_filename(a:opts.target_page)
  if !filereadable(l:path)
    throw 'wiki.vim: target page not found'
  endif


  if has_key(a:opts, 'target_anchor_before')
    return s:collect_target_by_anchor_before(
          \ l:path,
          \ a:opts.target_anchor_before,
          \ a:source
          \)
  endif

  return s:collect_target_by_lnum(l:path, a:opts.target_lnum, a:source)
endfunction

" }}}1
function! wiki#page#refile#move(source, target) abort " {{{1
  " Arguments:
  "   source: dict(path, lnum, lnum_end)
  "   target: dict(path, lnum)

  if a:target.level < a:source.level
    call execute(printf('%d,%dg/^#/normal! 0%dx',
          \ a:source.lnum, a:source.lnum_end, a:source.level - a:target.level))
  elseif a:target.level > a:source.level
    call execute(printf('%d,%dg/^#/normal! 0%di#',
          \ a:source.lnum, a:source.lnum_end, a:target.level - a:source.level))
  endif

  if a:target.path ==# a:source.path
    call execute(printf('%d,%dm %d',
          \ a:source.lnum, a:source.lnum_end, a:target.lnum))
    silent write
  else
    let l:lines = getline(a:source.lnum, a:source.lnum_end)
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
  endif
endfunction

" }}}1

function! s:collect_target_by_anchor_before(path, anchor, source) abort " {{{1
  let l:section = {}
  for l:section in wiki#toc#gather_entries(#{ path: a:path })
    if l:section.anchor ==# a:anchor
      break
    endif
  endfor

  if empty(l:section)
    throw 'wiki.vim: anchor not recognized'
  endif

  let l:anchors = get(l:section, 'anchors', [])
  if len(l:anchors) > 0
    call remove(l:anchors, -1)
  endif
  let l:anchors += [a:source.anchors[-1]]

  return #{
        \ path: a:path,
        \ lnum: l:section.lnum - 1,
        \ anchor: '#' . join(l:anchors, '#'),
        \ level: len(l:anchors)
        \}
endfunction

" }}}1
function! s:collect_target_by_lnum(path, lnum, source) abort " {{{1
  let l:anchors = [a:source.anchors[-1]]

  if a:source.level > 1
    let l:section = wiki#toc#get_section(#{ path: a:path, at_lnum: a:lnum })
    let l:target_anchors = get(l:section, 'anchors', [])
    call extend(
          \ l:anchors,
          \ l:target_anchors[:a:source.level - 2],
          \ 0
          \)
  endif

  return #{
        \ path: a:path,
        \ lnum: a:lnum,
        \ anchor: '#' . join(l:anchors, '#'),
        \ level: len(l:anchors)
        \}
endfunction

" }}}1
