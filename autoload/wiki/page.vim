" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#page#open(page) abort "{{{1
  let l:page =
        \ !empty(g:wiki_map_create_page) && exists('*' . g:wiki_map_create_page)
        \ ? call(g:wiki_map_create_page, [a:page])
        \ : a:page
  call wiki#url#parse('wiki:/' . l:page).follow()
endfunction

"}}}1
function! wiki#page#open_ask() abort "{{{1
  let l:page = input('Open/Create page: ')
  call wiki#page#open(l:page)
endfunction

"}}}1
function! wiki#page#delete() abort "{{{1
  let l:input_response = input('Delete "' . expand('%') . '" [y]es/[N]o? ')
  if l:input_response !~? '^y' | return | endif

  let l:filename = expand('%:p')
  try
    call delete(l:filename)
  catch
    return wiki#log#error('Cannot delete "' . expand('%:t:r') . '"!')
  endtry

  call wiki#nav#return()
  execute 'bdelete! ' . escape(l:filename, ' ')
endfunction

"}}}1
function! wiki#page#rename(newname, ...) abort "{{{1
  redraw!

  let l:dir_mode = get(a:, 1, 'abort')
  if index (['abort', 'ask', 'create'], l:dir_mode) ==? -1
    return wiki#log#error(
          \ 'The second argument to wiki#page#rename must be one of',
          \ '"abort", "ask", or "create"!',
          \ 'Recieved argument: ' . l:dir_mode,
          \)
  end

  let l:oldpath = expand('%:p')
  let l:newpath = wiki#paths#s(printf('%s/%s.%s',
        \ expand('%:p:h'), a:newname, b:wiki.extension))

  " Check if current file exists
  if !filereadable(l:oldpath)
    return wiki#log#error(
          \ 'Cannot rename "' . l:oldpath . '".',
          \ 'It does not exist! (New file? Save it before renaming.)'
          \)
  endif

  " Does not support renaming files inside journal
  if b:wiki.in_journal
    return wiki#log#error('Not supported yet.')
  endif

  " The new name must be nontrivial
  if empty(substitute(a:newname, '\s*', '', ''))
    return wiki#log#error('Cannot rename to an empty filename!')
  endif

  " The target path must not exist
  if filereadable(l:newpath)
    return wiki#log#error(
          \ 'Cannot rename to "' . l:newpath . '".',
          \ 'File with that name exist!'
          \)
  endif

  " Check if directory exists
  let l:target_dir = fnamemodify(l:newpath, ':p:h')
  if !isdirectory(l:target_dir)
    if l:dir_mode ==? 'abort'
      call wiki#log#warn(
            \ 'Directory "' . l:target_dir . '" does not exist. Aborting.')
      return
    elseif l:dir_mode ==? 'ask'
      redraw!
      call wiki#log#warn('Directory "' . l:target_dir . '" does not exist.')
      if input('Create it? [Y]es/[n]o: ', 'Y') !=? 'y'
        return
      endif
      echo '\n'
    end

    " At this point dir_mode is 'create' or the user said 'yes'
    call wiki#log#info('Creating directory "' . l:target_dir . '".')
    call mkdir(l:target_dir, 'p')
  endif

  " Rename current file to l:newpath
  let l:bufnr = bufnr('')
  try
    call wiki#log#info(
          \ printf('wiki: Renaming "%s" to "%s" ...',
          \   expand('%:t') , fnamemodify(l:newpath, ':t')))
    if rename(l:oldpath, l:newpath) != 0
      throw 'wiki.vim: Cannot rename file!'
    end
  catch
    return wiki#log#error(
          \ printf('Cannot rename "%s" to "%s"', expand('%:t:r') , l:newpath))
  endtry

  " Open new file and remove old buffer
  execute 'silent edit' l:newpath
  execute 'silent bwipeout' l:bufnr
  let l:bufnr = bufnr('')

  " Get list of open wiki buffers
  let l:bufs =
        \ map(
        \   filter(
        \     filter(range(1, bufnr('$')), 'buflisted(v:val)'),
        \     '!empty(getbufvar(v:val, ''wiki''))'),
        \   'fnamemodify(bufname(v:val), '':p'')')

  " Save other wiki buffers
  for l:bufname in l:bufs
    execute 'buffer' fnameescape(l:bufname)
    update
  endfor

  " Update links
  let l:oldlink = s:path_to_wiki_url(l:oldpath)
  let l:newlink = s:path_to_wiki_url(l:newpath)
  call s:rename_update_links(l:oldlink, l:newlink)

  " Refresh other wiki buffers
  for l:bufname in l:bufs
    execute 'buffer' fnameescape(l:bufname)
    edit
  endfor

  " Refresh tags
  silent call wiki#tags#reload()

  execute 'buffer' l:bufnr
endfunction

" }}}1
function! wiki#page#rename_ask() abort "{{{1
  " Ask if user wants to rename
  if input('Rename "' . expand('%:t:r') . '" [y]es/[N]o? ') !~? '^y'
    return
  endif

  " Get new page name
  redraw!
  call wiki#log#info('Enter new name (without extension):')
  let l:name = input('> ')

  call wiki#page#rename(l:name, 'ask')
endfunction

" }}}1
function! wiki#page#create_toc(local) abort " {{{1
  let l:entries = wiki#page#gather_toc_entries(getline(1, '$'), a:local)
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
function! wiki#page#gather_toc_entries(lines, local) abort " {{{1
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
function! wiki#page#get_anchors(...) abort " {{{1
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
function! wiki#page#get_title(...) abort " {{{1
  let l:filename = wiki#u#eval_filename(a:0 > 0 ? a:1 : '')
  if !filereadable(l:filename) | return '' | endif

  let preblock = 0
  for l:line in readfile(l:filename)
    " Ignore fenced code blocks
    if line =~# '^\s*```'
      let l:preblock += 1
    endif
    if l:preblock % 2 | continue | endif

    " Parse headers
    let l:match_header = matchlist(line, g:wiki#rx#header_items)
    if empty(l:match_header) | continue | endif

    return l:match_header[2]
  endfor
endfunction

" }}}1
function! wiki#page#export(line1, line2, ...) abort " {{{1
  let l:cfg = deepcopy(g:wiki_export)
  let l:cfg.fname = ''

  let l:args = copy(a:000)
  while !empty(l:args)
    let l:arg = remove(l:args, 0)
    if l:arg ==# '-args'
      let l:cfg.args = remove(l:args, 0)
    elseif l:arg =~# '\v^-f(rom_format)?$'
      let l:cfg.from_format = remove(l:args, 0)
    elseif l:arg ==# '-ext'
      let l:cfg.ext = remove(l:args, 0)
    elseif l:arg ==# '-output'
      let l:cfg.output = remove(l:args, 0)
    elseif l:arg ==# '-link-ext-replace'
      let l:cfg.link_ext_replace = v:true
    elseif l:arg ==# '-view'
      let l:cfg.view = v:true
    elseif l:arg ==# '-viewer'
      let l:cfg.view = v:true
      let l:cfg.viewer = remove(l:args, 0)
    elseif empty(l:cfg.fname)
      let l:cfg.fname = expand(simplify(l:arg))
    else
      return wiki#log#error(
            \ 'WikiExport argument "' . l:arg . '" not recognized',
            \ 'Please see :help WikiExport'
            \)
    endif
  endwhile

  " Ensure output directory is an absolute path
  if !wiki#paths#is_abs(l:cfg.output)
    let l:cfg.output = wiki#get_root() . '/' . l:cfg.output
  endif

  " Ensure output directory exists
  if !isdirectory(l:cfg.output)
    call mkdir(l:cfg.output, 'p')
  endif

  " Determine output filename and extension
  if empty(l:cfg.fname)
    let l:cfg.fname = wiki#paths#s(printf('%s/%s.%s',
          \ l:cfg.output, expand('%:t:r'), l:cfg.ext))
  else
    let l:cfg.ext = fnamemodify(l:cfg.fname, ':e')
  endif

  " Ensure '-link-ext-replace' is combined wiht '-ext html'
  if l:cfg.link_ext_replace && l:cfg.ext !=# 'html'
    return wiki#log#error(
          \ 'WikiExport option conflict!',
          \ 'Note: Option "-link-ext-replace" only works with "-ext html"',
          \)
  endif

  " Generate the output file
  call s:export(a:line1, a:line2, l:cfg)
  call wiki#log#info('Page was exported to ' . l:cfg.fname)

  if l:cfg.view
    call call(has('nvim') ? 'jobstart' : 'job_start',
          \ [[get(l:cfg, 'viewer', get(g:wiki_viewer,
          \     l:cfg.ext, g:wiki_viewer['_'])), l:cfg.fname]])
  endif
endfunction

" }}}1

function! s:rename_update_links(old, new) abort " {{{1
  let l:old_re = '(\.\/|\/)?' . escape(a:old, '.')

  " Pattern to search for relevant links
  let l:pattern  = '\v\[\[\zs' . l:old_re . '\ze%(#.*)?%(\|.*)?\]\]'
  let l:pattern .= '|\[.*\]\(\zs' . l:old_re . '\ze%(#.*)?\)'
  let l:pattern .= '|\[.*\]\[\zs' . l:old_re . '\ze%(#.*)?\]'
  let l:pattern .= '|\[\zs' . l:old_re . '\ze%(#.*)?\]\[\]'
  let l:pattern .= '\<\<\zs' . l:old_re . '\ze#,[^>]{-}\>\>'

  let l:num_files = 0
  let l:num_links = 0

  for l:file in glob(wiki#get_root() . '/**/*.' . b:wiki.extension, 0, 1)
    let l:updates = 0
    let l:lines = []
    for l:line in readfile(l:file)
      if match(l:line, l:pattern) != -1
        let l:updates = 1
        let l:num_links += 1
        call add(l:lines, substitute(l:line, l:pattern, a:new, 'g'))
      else
        call add(l:lines, l:line)
      endif
    endfor

    if l:updates
      call wiki#log#info('Updating links in: ' . fnamemodify(l:file, ':t'))
      call rename(l:file, l:file . '#tmp')
      call writefile(l:lines, l:file)
      call delete(l:file . '#tmp')
      let l:num_files += 1
    endif
  endfor
  call wiki#log#info(
        \ printf('Updated %d links in %d files', l:num_links, l:num_files))
endfunction

" }}}1
function! s:path_to_wiki_url(path) abort " {{{1
  let l:path = wiki#paths#shorten_relative(a:path)
  let l:ext = '.' . fnamemodify(l:path, ':e')
  if l:ext ==# g:wiki_link_extension
    return l:path
  else
    return fnamemodify(l:path, ':r')
  endif
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

function! s:export(start, end, cfg) abort " {{{1
  let l:fwiki = expand('%:p') . '.tmp'

  " Parse wiki page content
  let l:lines = getline(a:start, a:end)
  if a:cfg.link_ext_replace
    call s:convert_links_to_html(l:lines)
  endif

  let l:wiki_link_rx = '\[\[#\?\([^\\|\]]\{-}\)\]\]'
  let l:wiki_link_text_rx = '\[\[[^\]]\{-}|\([^\]]\{-}\)\]\]'
  call map(l:lines, 'substitute(v:val, l:wiki_link_rx, ''\1'', ''g'')')
  call map(l:lines, 'substitute(v:val, l:wiki_link_text_rx, ''\1'', ''g'')')
  call writefile(l:lines, l:fwiki)

  " Construct pandoc command
  let l:cmd = printf('pandoc %s -f %s -o %s %s',
        \ a:cfg.args,
        \ a:cfg.from_format,
        \ shellescape(a:cfg.fname),
        \ shellescape(l:fwiki))

  " Execute pandoc command
  call wiki#paths#pushd(fnamemodify(l:fwiki, ':h'))
  let l:output = system(l:cmd)
  call wiki#paths#popd()

  if v:shell_error == 127
    return wiki#log#error('Pandoc is required for this feature.')
  elseif v:shell_error > 0
    return wiki#log#error(
          \ 'Something went wrong when running cmd:',
          \ l:cmd,
          \ 'Shell output:',
          \ join(l:output, "\n"),
          \)
  endif

  call delete(l:fwiki)
endfunction

" }}}1
function! s:convert_links_to_html(lines) abort " {{{1
  if g:wiki_link_target_type ==# 'md'
    let l:rx = '\[\([^\\\[\]]\{-}\)\]'
          \ . '(\([^\(\)\\]\{-}\)' . g:wiki_link_extension
          \ . '\(#[^#\(\)\\]\{-}\)\{-})'
    let l:sub = '[\1](\2.html\3)'
  elseif g:wiki_link_target_type ==# 'wiki'
    let l:rx = '\[\[\([^\\\[\]]\{-}\)' . g:wiki_link_extension
          \ . '\(#[^#\\\[\]]\{-}\)'
          \ . '|\([^\[\]\\]\{-}\)\]\]'
    let l:sub = '\[\[\1.html\2|\3\]\]'
  else
    return wiki#log#error(
          \ 'g:wiki_link_target_type must be `md` or `wiki` to replace',
          \ 'link extensions on export.'
          \)
  endif

  call map(a:lines, 'substitute(v:val, l:rx, l:sub, ''g'')')
endfunction

" }}}1
