" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#page#open(page) abort "{{{1
  let l:page =
        \ !empty(g:wiki_map_create_page)
        \   && (type(g:wiki_map_create_page) == v:t_func
        \       || exists('*' . g:wiki_map_create_page))
        \ ? call(g:wiki_map_create_page, [a:page])
        \ : a:page
  call wiki#url#parse('wiki:/' . l:page).follow()
endfunction

"}}}1
function! wiki#page#open_ask() abort "{{{1
  let l:page = wiki#ui#input(#{info: 'Open page (or create new): '})
  if empty(l:page) | return | endif

  call wiki#page#open(l:page)
endfunction

"}}}1

function! wiki#page#delete() abort "{{{1
  if !wiki#ui#confirm(printf('Delete "%s"?', expand('%')))
    return
  endif

  let l:filename = expand('%:p')
  try
    call delete(l:filename)
  catch
    return wiki#log#error('Cannot delete "%s"!', expand('%:t:r'))
  endtry

  call wiki#nav#return()
  execute 'bdelete!' fnameescape(l:filename)
endfunction

"}}}1

function! wiki#page#rename() abort "{{{1
  " Ask if user wants to rename
  if !wiki#ui#confirm(printf('Rename "%s"?', expand('%:t:r')))
    return
  endif

  " Get new page name
  let l:name = wiki#ui#input(#{info: 'Enter new name (without extension):'})

  call wiki#page#rename_to(l:name, 'ask')
endfunction

" }}}1
function! wiki#page#rename_to(newname, ...) abort "{{{1
  redraw!

  let l:dir_mode = get(a:, 1, 'abort')
  if index(['abort', 'ask', 'create'], l:dir_mode) ==? -1
    return wiki#log#error(
          \ 'The second argument to wiki#page#rename_to must be one of',
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
      if !wiki#ui#confirm([
            \ prinft('Directory "%s" does not exist.', l:target_dir),
            \ 'Create it?'
            \])
        return
      endif
    end

    " At this point dir_mode is 'create' or the user said 'yes'
    call wiki#log#info('Creating directory "' . l:target_dir . '".')
    call mkdir(l:target_dir, 'p')
  endif

  " Rename current file to l:newpath
  let l:bufnr = bufnr('')
  try
    call wiki#log#info(
          \ printf('Renaming "%s" to "%s" ...',
          \   expand('%:t'),
          \   fnamemodify(l:newpath, ':t')))
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
  call s:update_links_in_wiki(l:oldpath, l:newpath)

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
function! wiki#page#rename_section() abort "{{{1
  call wiki#page#rename_section_to(
        \ wiki#ui#input(#{info: 'Enter new section name:'}))
endfunction

" }}}1
function! wiki#page#rename_section_to(newname) abort "{{{1
  let l:section = wiki#toc#get_section_at(line('.'))
  if empty(l:section)
    return wiki#log#error('No current section recognized!')
  endif

  call wiki#log#info(printf('Renaming section from "%s" to "%s"',
        \ l:section.header, a:newname))

  " Update header
  call setline(l:section.lnum,
        \ printf('%s %s',
        \   repeat('#', l:section.level),
        \   a:newname))

  " Update local anchors
  let l:pos = getcurpos()
  let l:new_anchor = join([''] + l:section.anchors[:-2] + [a:newname], '#')
  keepjumps execute '%s/\V' . l:section.anchor
        \ . '/' . l:new_anchor
        \ . '/e' . (&gdefault ? '' : 'g')
  call cursor(l:pos[1:])
  silent update

  " Update remote anchors
  let l:graph = wiki#graph#get_backlinks()
  call filter(l:graph, { _, x -> x.filename_from !=# x.filename_to })
  call filter(l:graph, { _, x -> '#' . x.anchor =~# l:section.anchor })

  let l:grouped_links = wiki#u#group_by(l:graph, 'filename_from')

  let l:n_files = 0
  let l:n_links = 0
  for [l:file, l:links] in items(l:grouped_links)
    let l:n_files += 1
    call wiki#log#info('Updating links in: ' . fnamemodify(l:file, ':t'))
    let l:lines = readfile(l:file)
    for l:link in l:links
      let l:n_links += 1
      let l:line = l:lines[l:link.lnum - 1]
      let l:lines[l:link.lnum - 1] = substitute(
            \ l:lines[l:link.lnum - 1],
            \ '\V' . l:section.anchor,
            \ l:new_anchor,
            \ 'g')
    endfor
    call writefile(l:lines, l:file)
  endfor

  call wiki#log#info(
        \ printf('Updated %d links in %d files', l:n_links, l:n_files))
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

function! s:update_links_in_wiki(path_old, path_new) abort " {{{1
  let l:root = wiki#get_root()

  " Update "absolute" links (i.e. assume link is rooted)
  let l:old = s:abspath_to_wikipath(l:root, a:path_old)
  let l:new = s:abspath_to_wikipath(l:root, a:path_new)
  let [l:n_files, l:n_links] = s:update_links_from_root(l:root, l:old, l:new)

  " Update "relative" links (look within the specific common subdir)
  let l:subdirs = []
  let l:old_subdirs = split(l:old, '\/')[:-2]
  let l:new_subdirs = split(l:new, '\/')[:-2]
  while !empty(l:old_subdirs)
        \ && !empty(l:new_subdirs)
        \ && l:old_subdirs[0] ==# l:new_subdirs[0]
    call add(l:subdirs, remove(l:old_subdirs, 0))
    call remove(l:new_subdirs, 0)
  endwhile
  if !empty(l:subdirs)
    let l:root .= '/' . join(l:subdirs, '/')
    let l:old = s:abspath_to_wikipath(l:root, a:path_old)
    let l:new = s:abspath_to_wikipath(l:root, a:path_new)
    let [l:n, l:m] = s:update_links_from_root(l:root, l:old, l:new)
    let l:n_files += l:n
    let l:n_links += l:m
  endif

  call wiki#log#info(
        \ printf('Updated %d links in %d files', l:n_links, l:n_files))
endfunction

" }}}1
function! s:update_links_from_root(root, oldlink, newlink) abort " {{{1
  let l:re_oldlink = '(\.\/|\/)?' . escape(a:oldlink, '.')

  " Pattern to search for relevant links
  let l:pattern = '\v' . join([
        \ '\[\[\zs' . l:re_oldlink . '\ze%(#.*)?%(\|.*)?\]\]',
        \ '\[.*\]\(\zs' . l:re_oldlink . '\ze%(#.*)?\)',
        \ '\[.*\]\[\zs' . l:re_oldlink . '\ze%(#.*)?\]',
        \ '\[\zs' . l:re_oldlink . '\ze%(#.*)?\]\[\]',
        \ '\<\<\zs' . l:re_oldlink . '\ze#,[^>]{-}\>\>',
        \], '|')

  let l:num_files = 0
  let l:num_links = 0

  for l:file in glob(a:root . '/**/*.' . b:wiki.extension, 0, 1)
    let l:updates = 0
    let l:lines = []
    for l:line in readfile(l:file)
      if match(l:line, l:pattern) != -1
        let l:updates = 1
        let l:num_links += 1
        call add(l:lines, substitute(l:line, l:pattern, a:newlink, 'g'))
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

  return [l:num_files, l:num_links]
endfunction

" }}}1
function! s:abspath_to_wikipath(root, path) abort " {{{1
  let l:path = wiki#paths#relative(a:path, a:root)
  let l:ext = '.' . fnamemodify(l:path, ':e')

  return l:ext ==# g:wiki_link_extension
        \ ? l:path
        \ : fnamemodify(l:path, ':r')
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
  let l:output = wiki#jobs#capture(l:cmd)
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
