" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#journal#open(...) abort " {{{1
  " Open a journal entry.
  "
  " OptionalArgument:
  "   date_string: A date string formatted according to the frequency format
  "                rules.
  "
  " With no arguments:
  "   Go to the current journal entry. This is usually the current date, but
  "   the g:wiki_journal.frequency setting has an effect here.

  let l:date = a:0 > 0
        \ ? a:1
        \ : strftime(s:date_format[g:wiki_journal.frequency])
  call wiki#url#follow('journal:' . l:date)
endfunction

" }}}1
function! wiki#journal#go(step) abort " {{{1
  let l:node = wiki#journal#get_current_node()
  if empty(l:node) | return | endif

  let l:frq = wiki#journal#get_node_frq(l:node)
  let l:nodes = wiki#journal#get_all_nodes(l:frq, [l:node])

  let l:index = index(l:nodes, l:node)
  let l:target = l:index + a:step
  if l:target >= len(l:nodes) || l:target < 0
    return
  endif
  let l:target_node = l:nodes[l:target]

  call s:follow_node(l:target_node)
endfunction

" }}}1
function! wiki#journal#go_to_frq(frq) abort " {{{1
  let [l:timestamp, l:frq] = wiki#journal#node_to_timestamp()
  if l:frq ==# a:frq | return | endif
  if l:timestamp == 0
    call wiki#log#warn(
          \ 'Current file is not a valid journal node!',
          \ expand('%:p'))
    return
  endif

  if (a:frq ==# 'daily' && g:wiki_journal.frequency !=# 'daily')
        \ || (a:frq ==# 'weekly' && g:wiki_journal.frequency ==# 'monthly')
    return
  endif

  call wiki#journal#open(strftime(s:date_format[a:frq], l:timestamp))
endfunction

" }}}1
function! wiki#journal#copy_to_next() abort " {{{1
  let [l:date, l:frq] = wiki#journal#node_to_date()
  if empty(l:date) | return | endif

  " Copy current note to next date - only if it does not exist
  let l:next_date = wiki#journal#get_next_date(l:date, l:frq)
  let l:node = wiki#journal#date_to_node(l:next_date)[0]
  let l:path = s:node_to_path(l:node)
  if !filereadable(l:path)
    execute 'write' l:path
  endif

  call wiki#journal#open(l:next_date)
endfunction

" }}}1
function! wiki#journal#make_index() " {{{1
  let l:nodes = wiki#journal#get_all_nodes(g:wiki_journal.frequency)

  let l:grouped_nodes = {}
  for l:node in l:nodes
    let l:date = wiki#date#parse_format(l:node, g:wiki_journal.date_format.daily)
    if has_key(grouped_nodes, l:date.year)
      let year_dict = grouped_nodes[l:date.year]
      if has_key(year_dict, l:date.month)
        call add(year_dict[l:date.month], l:node)
      else
        let year_dict[l:date.month] = [l:node]
      endif
    else
      let grouped_nodes[l:date.year] = {l:date.month:[l:node]}
    endif
  endfor

  let l:LinkUrlParser = g:wiki_journal_index.link_url_parser
  if type(l:LinkUrlParser) != v:t_func
    return wiki#log#error(
          \ 'g:wiki_journal_index.link_url_parser must be a function/lambda!')
  endif

  let l:LinkTextParser = g:wiki_journal_index.link_text_parser
  if type(l:LinkTextParser) != v:t_func
    return wiki#log#error(
          \ 'g:wiki_journal_index.link_text_parser must be a function/lambda!')
  endif

  " Put the index into buffer
  for l:year in sort(keys(l:grouped_nodes))
    let l:month_dict = l:grouped_nodes[l:year]
    put ='# ' . l:year
    put =''
    for l:month in sort(keys(l:month_dict))
      let l:nodes = l:month_dict[l:month]
      let l:mname = wiki#date#get_month_name(l:month)
      let l:mname = toupper(strcharpart(l:mname, 0, 1)) . strcharpart(l:mname, 1)
      put ='## ' . l:mname
      put =''
      for l:node in l:nodes
        let l:path = s:node_to_path(l:node)
        let l:date = wiki#journal#node_to_date(l:node)[0]

        let l:url = LinkUrlParser(l:node, l:date, l:path)
        let l:text = LinkTextParser(l:node, l:date, l:path)

        put =wiki#link#template(l:url, l:text)
      endfor
      put =''
    endfor
  endfor
endfunction

" }}}1

function! wiki#journal#get_root(...) abort " {{{1
  if !empty(g:wiki_journal.root)
    return g:wiki_journal.root
  endif

  let l:root_wiki = a:0 > 0 ? a:1 : wiki#get_root()
  return wiki#paths#s(
        \     printf('%s/%s', l:root_wiki, g:wiki_journal.name))
endfunction

" }}}1


" The following are functions to convert between journal nodes and date
" strings. Journal nodes are the file paths of the various journal entries with
" the journal root and extension removed. Thus, they are strings formatted
" according to g:wiki_journal.date_format. The date strings correspond to the
" frequencies (daily, weekly, monthly), but are currently not optional:
"   * daily:   YYYY-MM-DD
"   * weekly:  YYYY-wWW
"   * monthly: YYYY-MM

let s:date_format = {
      \ 'daily': '%Y-%m-%d',
      \ 'weekly': '%Y-w%V',
      \ 'monthly': '%Y-%m',
      \}

function! wiki#journal#date_to_node(...) abort " {{{1
  let l:date = a:0 > 0
        \ ? a:1
        \ : strftime(s:date_format[g:wiki_journal.frequency])

  let l:frq = get({
        \ 10: 'daily',
        \ 8: 'weekly',
        \ 7: 'monthly',
        \}, strlen(l:date), '')
  if empty(l:frq) | return [0, ''] | endif

  let l:timestamp = wiki#date#strptime(s:date_format[l:frq], l:date)
  let l:node = l:timestamp > 0
        \ ? strftime(get(g:wiki_journal.date_format, l:frq), l:timestamp)
        \ : ''

  return [l:node, l:frq]
endfunction

" }}}1
function! wiki#journal#get_next_date(date, frq) abort " {{{1
  let l:fmt = s:date_format[a:frq]
  let l:interval = get({
        \ 'daily': 1,
        \ 'weekly': 7,
        \ 'monthly': 31
        \}, a:frq, 0)

  let l:timestamp = wiki#date#strptime(l:fmt, a:date)
  let l:timestamp += l:interval*86400
  return strftime(l:fmt, l:timestamp)
endfunction

" }}}1

function! wiki#journal#node_to_timestamp(...) abort " {{{1
  let l:node = a:0 > 0
        \ ? a:1
        \ : wiki#journal#get_current_node()
  if empty(l:node) | return [0, ''] | endif

  let l:frq = wiki#journal#get_node_frq(l:node)
  if empty(l:frq) | return [0, ''] | endif

  return [wiki#date#strptime(g:wiki_journal.date_format[l:frq], l:node), l:frq]
endfunction

" }}}1
function! wiki#journal#node_to_date(...) abort " {{{1
  let [l:timestamp, l:frq] = call('wiki#journal#node_to_timestamp', a:000)

  let l:date = l:timestamp > 0
        \ ? strftime(s:date_format[l:frq], l:timestamp)
        \ : ''

  return [l:date, l:frq]
endfunction

" }}}1
function! wiki#journal#get_current_node() abort " {{{1
  if !exists('b:wiki') || !b:wiki.in_journal
    return ''
  endif

  return s:path_to_node(expand('%:p'))
endfunction

" }}}1
function! wiki#journal#get_node_frq(node) abort " {{{1
  for [l:frq, l:fmt] in items(g:wiki_journal.date_format)
    if a:node =~# wiki#date#format_to_regex(l:fmt)
      return l:frq
    endif
  endfor

  return ''
endfunction

" }}}1
function! wiki#journal#get_all_nodes(frq, ...) abort " {{{1
  let l:root = wiki#journal#get_root()
  let l:rx = wiki#date#format_to_regex(g:wiki_journal.date_format[a:frq])

  let l:nodes = filter(map(
        \   glob(wiki#paths#s(l:root . '/**'), 1, 1),
        \   { _, x -> s:path_to_node(x) }),
        \ { _, x -> x =~# l:rx })

  return a:0 > 0
        \ ? uniq(sort(a:1 + l:nodes))
        \ : l:nodes
endfunction

" }}}1

function! s:node_to_path(node) abort " {{{1
  let l:root = wiki#journal#get_root()

  let l:extension = exists('b:wiki.extension')
        \ ? b:wiki.extension
        \ : g:wiki_filetypes[0]

  return wiki#paths#s(printf('%s/%s.%s', l:root, a:node, l:extension))
endfunction

" }}}1
function! s:follow_node(node) abort " {{{1
  let l:path = s:node_to_path(a:node)

  " Use standard wiki rooted link if possible
  let l:wiki_path = wiki#paths#relative(l:path, wiki#get_root())
  if strlen(l:wiki_path) < strlen(l:path)
    return wiki#url#follow('/' . l:wiki_path)
  endif

  " Use file scheme if necessary
  return wiki#url#follow('file:' . l:path)
endfunction

" }}}1
function! s:path_to_node(path) abort " {{{1
  return wiki#paths#relative(
        \ fnamemodify(a:path, ':r'),
        \ wiki#journal#get_root())
endfunction

" }}}1
