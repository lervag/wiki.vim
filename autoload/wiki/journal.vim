" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#journal#make_note(...) abort " {{{1
  let l:date = (a:0 > 0 ? a:1
        \ : strftime(g:wiki_journal.date_format[g:wiki_journal.frequency]))
  call wiki#url#parse('journal:' . l:date).follow()
endfunction

" }}}1
function! wiki#journal#copy_note() abort " {{{1
  let l:next = s:get_next_entry()

  let l:next_entry = printf('%s/%s.%s',
        \ b:wiki.root_journal, l:next, b:wiki.extension)
  if !filereadable(l:next_entry)
    execute 'write' l:next_entry
  endif

  call wiki#url#parse('journal:' . l:next).follow()
endfunction

" }}}1
function! wiki#journal#go(step) abort " {{{1
  let l:links = s:get_links()
  let l:index = index(l:links, expand('%:t:r'))
  let l:target = l:index + a:step

  if l:target >= len(l:links) || l:target < 0
    return
  endif

  call wiki#url#parse('journal:' . l:links[l:target]).follow()
endfunction

" }}}1
function! wiki#journal#freq(frq) abort " {{{1
  if a:frq ==# 'daily'
    return
  endif
  if a:frq ==# 'weekly' && g:wiki_journal.frequency !=# 'daily'
    return
  endif
  if a:frq ==# 'monthly' && g:wiki_journal.frequency ==# 'monthly'
    return
  endif

  let l:filedate = expand('%:t:r')
  let l:fmt = g:wiki_journal.date_format.daily
  let l:rx = wiki#date#format_to_regex(l:fmt)
  let l:date = l:filedate =~# l:rx ? l:filedate : strftime(l:fmt)

  call wiki#url#parse('journal:'
        \ . wiki#date#format(l:date, g:wiki_journal.date_format[a:frq])).follow()
endfunction

" }}}1
function! wiki#journal#make_index() " {{{1
  let l:fmt = g:wiki_journal.date_format[g:wiki_journal.frequency]
  let l:rx = wiki#date#format_to_regex(l:fmt)
  let l:entries = s:get_links_generic(l:rx, l:fmt)

  let l:sorted_entries = {}
  for entry in entries
    let date = wiki#date#parse_format(entry, g:wiki_journal.date_format.daily)
    if has_key(sorted_entries, date.year)
      let year_dict = sorted_entries[date.year]
      if has_key(year_dict, date.month)
        call add(year_dict[date.month], entry)
      else
        let year_dict[date.month] = [entry]
      endif
    else
      let sorted_entries[date.year] = {date.month:[entry]}
    endif
  endfor

  for year in reverse(sort(keys(sorted_entries)))
    let l:month_dict = sorted_entries[year]
    put ='# ' . year
    put =''
    for [month, entries] in items(month_dict)
      let l:mname = wiki#date#get_month_name(month)
      let l:mname = toupper(mname[0]) . mname[1:strlen(mname)]
      put ='## ' . mname
      put =''
      for entry in entries
        put =wiki#link#template('journal:' . entry, entry)
      endfor
      put =''
    endfor
  endfor
endfunction

" }}}1

function! s:get_next_entry() abort " {{{1
  let l:current = expand('%:t:r')

  for [l:freq, l:fmt] in items(g:wiki_journal.date_format)
    let l:rx = wiki#date#format_to_regex(l:fmt)
    if l:current =~# l:rx
      let l:date_dict = wiki#date#parse_format(l:current, l:fmt)
      let l:date = printf('%4d-%2d-%2d',
            \ l:date_dict.year, l:date_dict.month, l:date_dict.day)
      let l:next = wiki#date#offset(l:date, {
            \ 'daily' : '1 day',
            \ 'weekly' : '1 week',
            \ 'monthly' : '1 month',
            \}[l:freq])
      return wiki#date#format(l:next, l:fmt)
    endif
  endfor

  throw printf('Error: %s was not matched by any date formats', l:current)
endfunction

" }}}1

function! s:get_links() abort " {{{1
  let l:current = expand('%:t:r')

  for l:fmt in values(g:wiki_journal.date_format)
    let l:rx = wiki#date#format_to_regex(l:fmt)
    if l:current =~# l:rx
      return s:get_links_generic(l:rx, l:fmt)
    endif
  endfor

  return []
endfunction

" }}}1
function! s:get_links_generic(rx, fmt) abort " {{{1
  let l:globpat = printf('%s/*.%s', b:wiki.root_journal, b:wiki.extension)
  let l:links = filter(map(glob(l:globpat, 0, 1),
        \   'fnamemodify(v:val, '':t:r'')'),
        \ 'v:val =~# a:rx')

  for l:cand in [
        \ strftime(a:fmt),
        \ expand('%:t:r'),
        \]
    if l:cand =~# a:rx && index(l:links, l:cand) == -1
      call add(l:links, l:cand)
      let l:sort = 1
    endif
  endfor

  return get(l:, 'sort', 0) ? sort(l:links) : l:links
endfunction

" }}}1
