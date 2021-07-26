" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#template#init() abort " {{{1
  if filereadable(expand('%')) | return | endif

  let l:origin = wiki#nav#get_previous()

  let l:context = {
        \ 'date': strftime("%F"),
        \ 'name': expand('%:t:r'),
        \ 'origin_file': l:origin[0],
        \ 'origin_lnum': l:origin[1][1],
        \ 'path': expand('%:p'),
        \ 'path_wiki': wiki#paths#shorten_relative(expand('%:p')),
        \ 'time': strftime("%H:%M"),
        \}

  for l:template in g:wiki_templates
    if s:template_match(l:template, l:context)
      if s:template_apply(l:template, l:context) | return | endif
    endif
  endfor

  let l:match = matchlist(expand('%:t:r'), '^\(\d\d\d\d\)_\(\w\)\(\d\d\)$')
  if empty(l:match) | return | endif
  let [l:year, l:type, l:number] = l:match[1:3]

  if l:type ==# 'w'
    call wiki#template#weekly_summary(l:year, l:number)
  elseif l:type ==# 'm'
    call wiki#template#monthly_summary(l:year, l:number)
  endif
endfunction

" }}}1

function! wiki#template#case_title(ctx, text) abort " {{{1
  return join(map(split(a:text), {_, x -> toupper(x[0]) . strpart(x, 1)}))
endfunction

" }}}1


function! s:template_match(t, ctx) abort " {{{1
  if has_key(a:t, 'match_re')
    return a:ctx.name =~# a:t.match_re
  elseif has_key(a:t, 'match_func')
    return a:t.match_func(a:ctx)
  endif
endfunction

" }}}1
function! s:template_apply(t, ctx) abort " {{{1
  if has_key(a:t, 'source_func')
    call a:t.source_func(a:ctx)
    return 1
  endif

  let l:source = get(a:t, 'source_filename', '')
  if !filereadable(l:source) | return 0 | endif

  " Interpolate the context "variables"
  let l:lines = join(readfile(l:source), "\n")
  for [l:key, l:value] in items(a:ctx)
    let l:lines = substitute(l:lines, '{' . l:key . '}', l:value, 'g')
  endfor

  " Interpolate user functions
  let [l:match, l:c1, l:c2] = matchstrpos(l:lines, '{{[a-zA-Z#_0-9]\+\s*[^}]*}}')
  while !empty(l:match)
    let l:parts = matchlist(l:match, '{{\([a-zA-Z#_0-9]\+\)\s*\([^}]*\)}}')
    let l:func = l:parts[1]
    let l:arg = trim(l:parts[2])
    let l:args = [a:ctx] + (!empty(l:arg) ? [l:arg] : [])
    try
      let l:value = call(l:func, l:args)
    catch /E117:/
      let l:value = ''
    endtry

    let l:pre = l:lines[:l:c1-1]
    let l:post = l:lines[l:c2:]
    let l:lines = l:pre . l:value . l:post

    let [l:match, l:c1, l:c2] = matchstrpos(
          \ l:lines, '{{[a-zA-Z#_0-9]\+\s*[^}]*}}', l:c2+1)
  endwhile

  call append(0, split(l:lines, "\n"))

  return 1
endfunction

" }}}1

function! wiki#template#weekly_summary(year, week) abort " {{{1
  let l:parser = s:summary.new()

  let l:title = copy(g:wiki_template_title_week)
  let l:title = substitute(l:title, '%(week)', a:week, 'g')
  let l:title = substitute(l:title, '%(year)', a:year, 'g')

  let l:links = wiki#date#get_week_dates(a:week, a:year)

  call append(0, [l:title] + l:parser.parse(l:links))
  call setpos('.', [0, 3, 0, 0])
endfunction

" }}}1
function! wiki#template#monthly_summary(year, month) abort " {{{1
  let l:parser = s:summary.new()

  let l:title = copy(g:wiki_template_title_month)
  let l:title = substitute(l:title, '%(month)', a:month, 'g')
  let l:title = substitute(l:title, '%(month-name)',
        \ wiki#date#get_month_name(a:month), 'g')
  let l:title = substitute(l:title, '%(year)', a:year, 'g')

  let l:links = wiki#date#get_month_decomposed(a:month, a:year)

  call append(0, [l:title] + l:parser.parse(l:links))
  call setpos('.', [0, 3, 0, 0])
endfunction

" }}}1


let s:summary = {}
function! s:summary.new() abort dict " {{{1
  let l:summary = deepcopy(self)
  let l:summary.entries = {}
  return l:summary
endfunction

" }}}1
function! s:summary.parse(links) abort dict " {{{1
  let self.links = map(filter(copy(a:links),
        \   'filereadable(v:val . ''.'' . b:wiki.extension)'),
        \ '''journal:'' . v:val')

  for l:link in self.links
    call self.parse_link(l:link)
  endfor

  return [''] + self.links + self.get_entries()
endfunction

" }}}1
function! s:summary.parse_link(link) abort dict " {{{1
  let l:link = wiki#url#parse(a:link)

  let l:order = 1
  let l:entry = {
        \ 'title' : '',
        \ 'lines' : [],
        \ 'order' : l:order,
        \ 'ignore' : 0,
        \}

  let l:lnum = 0
  for l:line in readfile(l:link.path)
    let l:lnum += 1

    " Ignore everything after title lines (except in weekly summaries)
    if l:line =~# '^\#'
      if l:lnum > 1 | break | endif
      continue
    endif

    " Empty lines separate entries
    if l:line =~# '^\s*$'
      if !empty(l:entry.lines)
        let l:order += 1

        if has_key(self.entries, l:entry.title)
          let self.entries[l:entry.title].lines += l:entry.lines[1:]
          let self.entries[l:entry.title].order = max([l:entry.order,
                \ self.entries[l:entry.title].order])
        else
          let self.entries[l:entry.title] = l:entry
        endif
      endif

      let l:entry = {
            \ 'title' : '',
            \ 'lines' : [],
            \ 'order' : l:order,
            \ 'ignore' : 0,
            \}
      continue
    endif

    " Ignore tables
    if l:line =~# '^\s*|-\+'
      let l:entry.ignore = 1
    endif

    if l:entry.ignore | continue | endif

    " Detect header of entries
    if empty(l:entry.title)
      let l:entry.title = l:line
      call add(l:entry.lines, l:line)
      continue
    endif

    " Fix pure-anchor links
    if l:link.stripped =~# '\d\{4}-\d\d-\d\d'
      let l:line = substitute(l:line, '\(\[\[\|\](\)\zs\ze\#',
            \ fnamemodify(l:link.path, ':t:r'), 'g')
    endif

    call add(l:entry.lines, l:line)
  endfor
endfunction

" }}}1
function! s:summary.get_entries() abort dict " {{{1
  let l:lines = []
  let l:parsed_entries = []

  let l:next = 1
  while len(l:parsed_entries) < len(self.entries)
    for [l:title, l:entry] in items(self.entries)
      if l:entry.order == l:next
        let l:lines += ['']
        let l:lines += l:entry.lines
        call add(l:parsed_entries, l:title)
      endif
    endfor
    let l:next += 1
  endwhile

  return l:lines
endfunction

" }}}1

