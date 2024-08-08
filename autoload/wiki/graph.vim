" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#graph#check_links(...) abort "{{{1
  let l:graph = wiki#graph#builder#get()

  if a:0 > 0
    let l:broken_links = l:graph.get_broken_links_from(a:1)
  else
    let l:broken_links = l:graph.get_broken_links_global()
  endif

  if empty(l:broken_links)
    call wiki#log#info('No broken links found.')
    return
  endif

  call map(l:broken_links,
        \ { _, x -> {
        \   'filename': x.filename_from,
        \   'text': x.content,
        \   'anchor': x.anchor,
        \   'lnum': x.lnum,
        \   'col': x.col
        \ }
        \})

  call setloclist(0, l:broken_links, 'r')
  lopen
endfunction

"}}}1
function! wiki#graph#check_orphans() abort "{{{1
  let l:graph = wiki#graph#builder#get()

  " Fully refresh the cache - this takes some extra time, but it ensures that
  " the data is up to date.
  call l:graph.refresh_cache(#{force: v:true})

  " Manually fetch data from the cache
  let l:orphans = keys(filter(
        \ deepcopy(l:graph.cache_links_in.data),
        \ { file, links ->
        \   type(links) == v:t_list
        \   && empty(links)
        \   && !wiki#journal#is_in_journal(file)
        \ }
        \))

  if empty(l:orphans)
    call wiki#log#info('No orphans found.')
    return
  endif

  call map(l:orphans, { _, x -> {
        \   'filename': x,
        \   'text': 'Does not have any incoming links'
        \ }
        \})

  call setloclist(0, l:orphans, 'r')
  lopen
endfunction

"}}}1
function! wiki#graph#get_number_of_broken_links(file) abort "{{{1
  let l:cache = wiki#cache#open('broken-links-numbers', {
        \ 'local': 1,
        \ 'default': { 'ftime': -1, 'number': 0 },
        \})

  let l:current = l:cache.get(a:file)
  let l:ftime = getftime(a:file)
  if l:ftime > l:current.ftime
    let l:current.ftime = l:ftime

    let l:graph = wiki#graph#builder#get()
    let l:current.number = len(l:graph.get_broken_links_from(a:file))
    call l:cache.write('force')
  endif

  return l:current.number
endfunction

"}}}1
function! wiki#graph#get_backlinks_enriched() abort "{{{1
  let l:toc = wiki#u#associate_by(wiki#toc#gather_entries(), 'anchor')

  let l:graph = wiki#graph#builder#get()
  let l:links = l:graph.get_links_to(expand('%:p'), #{nudge: v:true})

  for l:link in l:links
    let l:section = get(l:toc, remove(l:link, 'anchor'), {})
    let l:link.target_lnum = get(l:section, 'lnum', 0)
  endfor

  return l:links
endfunction

"}}}1
function! wiki#graph#find_backlinks() abort "{{{1
  let l:file = expand('%:p')
  if !filereadable(l:file)
    call wiki#log#info("Can't find backlinks for unsaved file!")
    return []
  endif

  let l:graph = wiki#graph#builder#get()
  let l:links = l:graph.get_links_to(l:file)

  if empty(l:links)
    call wiki#log#info('No other file links to this file')
    return
  endif

  for l:link in l:links
    let l:link.filename = l:link.filename_from
    let l:link.text = readfile(l:link.filename, 0, l:link.lnum)[-1]
  endfor

  call setloclist(0, l:links, 'r')
  lopen
endfunction

"}}}1
function! wiki#graph#show_related() abort "{{{1
  let l:graph = wiki#graph#builder#get()

  " Create lines - iterate over links into page
  let l:links_in = uniq(sort(map(
        \ l:graph.get_links_to(expand('%:p')),
        \ { _, x -> wiki#paths#to_node(x.filename_from) }), 'i'))

  if empty(l:links_in)
    let l:n_current_in = 0
    let l:lines = ['']
    let l:width_in = 0
  else
    if len(l:links_in) == 1
      let l:n_current_in = 0
      let l:lines = [printf(' %s ───', l:links_in[0])]
    else
      let l:width = max(map(copy(l:links_in), { _, x -> strchars(x) } ))
      let l:fmt = ' %' . l:width . 'S ─┤'
      let l:width += 3
      let l:lines = map(l:links_in, { _, x -> printf(l:fmt, x) } )
      let l:lines[0] = strcharpart(l:lines[0], 0, l:width) . '┐'
      let l:lines[-1] = strcharpart(l:lines[-1], 0, l:width) . '┘'
      if len(l:links_in) == 2
        let l:n_current_in = 1
        call insert(l:lines, repeat(' ', l:width) . '├─', 1)
      else
        let l:n_current_in = float2nr(ceil(len(l:lines) / 2.0) - 1)
        let l:lines[l:n_current_in] =
              \ strcharpart(l:lines[l:n_current_in], 0, l:width) . '┼─'
      endif
    endif
    let l:width_in = strchars(l:lines[l:n_current_in]) - 3
  endif

  " Add current node in the middle
  let l:lines[l:n_current_in] .= ' ' . wiki#paths#to_node(expand('%:p'))

  " Now iterate over links out of page and iterate to merge lines
  let l:links_out = uniq(sort(map(
        \ l:graph.get_links_from(expand('%:p')),
        \ { _, x -> wiki#paths#to_node(x.filename_to) }), 'i'))

  if empty(l:links_out)
    let l:width_out = strchars(l:lines[l:n_current_in]) + 1
  else
    let l:width_out = strchars(l:lines[l:n_current_in]) + 4
    if len(l:links_out) == 1
      let l:lines[l:n_current_in] .= ' ─── ' . l:links_out[0]
    else
      call map(l:links_out, { _, x -> '├─ ' . x } )
      let l:links_out[0] = '┌' . strcharpart(l:links_out[0], 1)
      let l:links_out[-1] = '└' . strcharpart(l:links_out[-1], 1)
      if len(l:links_out) == 2
        let l:n_current_out = 1
        call insert(l:links_out, '┤', 1)
      else
        let l:n_current_out = float2nr(ceil(len(l:links_out) / 2.0) - 1)
        let l:links_out[l:n_current_out]
              \ = '┼' . strcharpart(l:links_out[l:n_current_out], 1)
      endif

      " Merge initial lines with lines of links out
      let l:lines[l:n_current_in] .= ' ─'
      let l:fmt = '%-' . strchars(l:lines[l:n_current_in]) . 'S%s'
      let l:shift = l:n_current_in - l:n_current_out
      if len(l:links_out) < len(l:lines)
        for l:i in range(l:shift, l:shift + len(l:links_out) - 1)
          let l:lines[l:i]
                \ = printf(l:fmt, l:lines[l:i], l:links_out[l:i - l:shift])
        endfor
      else
        let l:links_in = copy(l:lines)
        let l:lines = l:links_out
        for l:i in range(len(l:lines))
          let l:pretext = l:i + l:shift >= 0 && l:i + l:shift < len(l:links_in)
                \ ? l:links_in[l:i+l:shift]
                \ : ''
          let l:lines[l:i] = printf(l:fmt, l:pretext, l:lines[l:i])
        endfor
      endif
    endif
  endif

  " Create scratch buffer with lines as content
  let l:scratch = {
        \ 'name': 'WikiGraphRelated',
        \ 'lines': l:lines,
        \ 'width_in': l:width_in,
        \ 'width_out': l:width_out
        \}

  function! l:scratch.post_init() abort dict
    nnoremap <silent><buffer> o    :call b:scratch.action(0)<cr>
    nnoremap <silent><buffer> <cr> :call b:scratch.action(1)<cr>
  endfunction

  function! l:scratch.action(continue_in_graph) abort dict
    let l:col = col('.')
    let l:line = getline('.')

    if l:col < self.width_in
      let l:name = strcharpart(l:line, 0, self.width_in)
    elseif l:col > self.width_out
      let l:name = strcharpart(l:line, self.width_out)
    else
      return self.close()
    endif

    let l:url = trim(l:name)
    if !empty(l:url)
      call wiki#url#follow(l:url)
      if a:continue_in_graph
        WikiGraphRelated
      endif
    endif
  endfunction

  function! l:scratch.print_content() abort dict
    for l:line in self.lines
      call append('$', l:line)
    endfor
  endfunction

  function! l:scratch.syntax() abort dict
    syntax match ScratchContent "."
    syntax match ScratchSeparator "[─┤┐┘├┼└┌]"

    highlight link ScratchContent Include
    highlight link ScratchSeparator Title
  endfunction

  call wiki#scratch#new(l:scratch)
endfunction

"}}}1
function! wiki#graph#in(...) abort "{{{1
  let l:graph = wiki#graph#builder#get()

  call wiki#log#info('Building tree, please wait ...')
  sleep 10m

  let l:depth = a:0 > 0 ? a:1 : -1
  let l:tree = l:graph.get_tree_to(expand('%:p'), l:depth)

  redraw
  call wiki#log#info('Building tree, please wait ... done!')

  call s:output_to_scratch('WikiGraphIn', sort(values(l:tree)))
endfunction

"}}}1
function! wiki#graph#out(...) abort " {{{1
  let l:graph = wiki#graph#builder#get()

  call wiki#log#info('Building tree, please wait ...')
  sleep 10m

  let l:depth = a:0 > 0 ? a:1 : -1
  let l:tree = l:graph.get_tree_from(expand('%:p'), l:depth)

  redraw
  call wiki#log#info('Building tree, please wait ... done!')

  call s:output_to_scratch('WikiGraphOut', sort(values(l:tree)))
endfunction

" }}}1

function! wiki#graph#mark_refreshed(file) abort " {{{1
  if !empty(a:file)
    let l:graph = wiki#graph#builder#get()
    call l:graph.mark_refreshed(a:file)
  endif
endfunction

" }}}1


function! s:output_to_scratch(name, lines) abort " {{{1
  let l:scratch = {
        \ 'name': a:name,
        \ 'lines': a:lines,
        \}

  function! l:scratch.print_content() abort dict
    for l:line in self.lines
      call append('$', l:line)
    endfor
  endfunction

  function! l:scratch.syntax() abort dict
    syntax match ScratchSeparator /\//
    highlight link ScratchSeparator Title
  endfunction

  call wiki#scratch#new(l:scratch)
endfunction

" }}}1
