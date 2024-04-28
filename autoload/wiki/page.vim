" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#page#open(...) abort "{{{1
  let l:page = a:0 > 0
        \ ? a:1
        \ : wiki#ui#input(#{info: 'Open page (or create new): '})
  if empty(l:page) | return | endif

  " Apply url transformer if available
  let l:link_creator = wiki#link#get_creator()
  if has_key(l:link_creator, 'url_transform')
    try
      let l:page = l:link_creator.url_transform(l:page)
    catch
      call wiki#log#warn('There was a problem with the url transformer!')
    endtry
  endif

  call wiki#url#follow('/' .. l:page)
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
  execute 'bwipeout!' fnameescape(l:filename)
endfunction

"}}}1
function! wiki#page#rename(...) abort "{{{1
  " This function renames a wiki page to a new name. The names used here are
  " filenames without the extension. The outer function parses the options and
  " validates the parameters before passing them to dedicated private
  " functions.
  "
  " Input: An optional dictionary with the following keys:
  "   dir_mode: "ask" (default), "abort" or "create"
  "   new_name: The new page name

  " Does not support renaming files inside journal
  if b:wiki.in_journal
    return wiki#log#error('Not supported yet.')
  endif

  let l:opts = extend(#{
        \ dir_mode: 'ask',
        \ new_name: '',
        \}, a:0 > 0 ? a:1 : {})

  if index(['abort', 'ask', 'create'], l:opts.dir_mode) < 0
    return wiki#log#error(
          \ 'The dir_mode option for wiki#page#rename must be one of',
          \ '"abort", "ask", or "create"!',
          \ 'Recieved: ' .. l:opts.dir_mode,
          \)
  end

  if empty(l:opts.new_name)
    let l:opts.new_name = wiki#ui#input(
          \ #{info: 'Enter new name (without extension) [empty cancels]:'})
  endif
  if empty(l:opts.new_name) | return | endif

  " The new name must be nontrivial
  if empty(substitute(l:opts.new_name, '\s*', '', ''))
    return wiki#log#error('Cannot rename to a whitespace filename!')
  endif

  " Check if current file exists
  let l:source = #{ path: expand('%:p') }
  if !filereadable(l:source.path)
    return wiki#log#error(
          \ 'Cannot rename "' .. l:source.path .. '".',
          \ 'It does not exist! (New file? Save it before renaming.)'
          \)
  endif

  " The target path must not exist
  let l:target = {}
  let l:target.path = wiki#paths#s(printf('%s/%s.%s',
        \ expand('%:p:h'), l:opts.new_name, b:wiki.extension))
  if filereadable(l:target.path)
    return wiki#log#error(
          \ 'Cannot rename to "' .. l:target.path .. '".',
          \ 'File with that name exist!'
          \)
  endif

  " Check if target directory exists
  let l:target_dir = fnamemodify(l:target.path, ':p:h')
  if !isdirectory(l:target_dir)
    if l:opts.dir_mode ==# 'abort'
      call wiki#log#warn(
            \ 'Directory "' .. l:target_dir .. '" does not exist. Aborting.')
      return
    elseif l:opts.dir_mode ==# 'ask'
      if !wiki#ui#confirm([
            \ printf('Directory "%s" does not exist.', l:target_dir),
            \ 'Create it?'
            \])
        return
      endif
    end

    call wiki#log#info('Creating directory "' .. l:target_dir .. '".')
    call mkdir(l:target_dir, 'p')
  endif

  try
    call s:rename_file(l:source.path, l:target.path)
  catch
    return wiki#log#error(
          \ printf('Cannot rename "%s" to "%s" ...',
          \   fnamemodify(l:source.path, ':t'),
          \   fnamemodify(l:target.path, ':t')))
  endtry

  call s:update_links_external(l:source, l:target)
endfunction

" }}}1
function! wiki#page#rename_section(...) abort "{{{1
  let l:source = wiki#toc#get_section()
  if empty(l:source)
    return wiki#log#error('No current section recognized!')
  endif

  let l:target = {}
  let l:target.name = a:0 > 0
        \ ? a:1
        \ : wiki#ui#input(#{info: 'Enter new section name:'})
  if empty(substitute(l:target.name, '\s*', '', ''))
    return wiki#log#warn('New section name cannot be empty!')
  endif
  let l:target.anchor = join(
        \ [''] + l:source.anchors[:-2] + [l:target.name], '#')

  call wiki#log#info(
        \ printf('Renaming section from "%s" to "%s"',
        \ l:source.header, l:target.name))

  " Update header
  call setline(l:source.lnum,
        \ printf('%s %s', repeat('#', l:source.level), l:target.name))
  silent write

  call s:update_links_local(l:source, l:target)
  call s:update_links_external(l:source, l:target)
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
            \ 'WikiExport argument "' .. l:arg .. '" not recognized',
            \ 'Please see :help WikiExport'
            \)
    endif
  endwhile

  " Ensure output directory is an absolute path
  if !wiki#paths#is_abs(l:cfg.output)
    let l:cfg.output = wiki#get_root() .. '/' .. l:cfg.output
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
  call wiki#log#info('Page was exported to ' .. l:cfg.fname)

  if l:cfg.view
    call call(has('nvim') ? 'jobstart' : 'job_start',
          \ [[get(l:cfg, 'viewer', get(g:wiki_viewer,
          \     l:cfg.ext, g:wiki_viewer['_'])), l:cfg.fname]])
  endif
endfunction

" }}}1

function! wiki#page#get_all() abort " {{{1
  " Return: List of pairs
  "   first element:  absolute path
  "   second element: relative path to wiki root

  let l:root = wiki#get_root() .. s:slash

  " Note: It may be tempting to do a globpath() with a single pattern
  "       `**/*.{ext1,ext2,...}`, but this is not portable. On at least some
  "       very common systems, brace-expansion is incompatible with recursive
  "       `**` globbing and turns the latter into a non-recursive `*`.
  let l:pages = []
  for l:extension in g:wiki_filetypes
    let l:pages += globpath(l:root, '**/*.' .. l:extension, v:false, v:true)
  endfor

  " Enrich the results with paths from wiki root and up
  call map(l:pages, {_, x ->
        \ [
        \   x,
        \   '/' .. fnamemodify(
        \     substitute(x, '\V' .. escape(l:root, '\'), '', ''), ':r')
        \ ]
        \})

  return l:pages
endfunction

let s:slash = exists('+shellslash') && !&shellslash ? '\' : '/'

" }}}1

function! s:rename_file(path_old, path_new) abort "{{{1
  let l:bufnr = bufnr('')
  call wiki#log#info(
        \ printf('Renaming "%s" to "%s" ...',
        \   fnamemodify(a:path_old, ':t'),
        \   fnamemodify(a:path_new, ':t')))
  if rename(a:path_old, a:path_new) != 0
    throw 'wiki.vim: Cannot rename file!'
  end

  " Open new file and remove old buffer
  execute 'silent edit' a:path_new
  execute 'silent bwipeout' l:bufnr

  " Tag data may be changed as a result of renaming files
  silent call wiki#tags#reload()
endfunction

" }}}1
function! s:update_links_local(old, new) abort "{{{1
  " Arguments:
  "   old: dict(anchor)
  "   new: dict(anchor)
  let l:pos = getcurpos()
  keeppattern keepjumps execute printf('%%s/\V%s/%s/e%s',
        \ a:old.anchor,
        \ a:new.anchor,
        \ &gdefault ? '' : 'g')
  silent update
  call cursor(l:pos[1:])
endfunction

" }}}1
function! s:update_links_external(old, new) abort "{{{1
  " Arguments:
  "   old: dict(anchor?, path?)
  "   new: dict(anchor?, path)

  let l:old = extend(#{anchor: '', path: expand('%:p')}, a:old)
  let l:new = extend(#{anchor: '', path: ''}, a:new)

  let l:current_bufnr = bufnr('')

  " Save all open wiki buffers (prepare for updating links)
  let l:wiki_bufnrs = filter(range(1, bufnr('$')),
        \ {_, x -> buflisted(x) && !empty(getbufvar(x, 'wiki'))})
  for l:bufnr in l:wiki_bufnrs
    execute 'buffer' l:bufnr
    silent update
  endfor

  " Update links
  let l:graph = wiki#graph#builder#get()
  let l:links = l:graph.get_links_to(l:old.path, {'nudge': v:true})
  if !empty(l:old.anchor)
    call filter(l:links, { _, x -> x.anchor =~# '^' .. l:old.anchor })
  endif
  let l:files_with_links = wiki#u#group_by(l:links, 'filename_from')

  let l:replacement_patterns = !empty(l:new.path)
        \ ? s:get_replacement_patterns(l:old.path, l:new.path)
        \ : []
  for [l:file, l:file_links] in items(l:files_with_links)
    let l:lines = readfile(l:file)

    for l:link in l:file_links
      " Update file
      for [l:pattern, l:replace] in l:replacement_patterns
        let l:lines[l:link.lnum - 1] = substitute(
              \ l:lines[l:link.lnum - 1],
              \ l:pattern, l:replace, 'g')
      endfor

      " Update anchor
      if !empty(l:old.anchor)
        let l:lines[l:link.lnum - 1] = substitute(
              \ l:lines[l:link.lnum - 1],
              \ l:old.anchor, l:new.anchor, 'g')
      endif
    endfor

    call writefile(l:lines, l:file, 's')
  endfor

  call l:graph.mark_tainted(l:old.path)

  " Refresh other wiki buffers
  for l:bufnr in l:wiki_bufnrs
    execute 'buffer' l:bufnr
    silent edit
  endfor

  " Restore the original buffer
  execute 'buffer' l:current_bufnr

  call wiki#log#info(
        \ printf('Updated %d links in %d files',
        \ len(l:links), len(l:files_with_links)))
endfunction

" }}}1
function! s:get_replacement_patterns(path_old, path_new) abort " {{{1
  " Update "absolute" links (i.e. assume link is rooted)
  let l:root = wiki#get_root()
  let l:url_old = wiki#paths#to_wiki_url(a:path_old, l:root)
  let l:url_new = wiki#paths#to_wiki_url(a:path_new, l:root)
  let l:url_pairs = [[l:url_old, l:url_new]]

  " Update "relative" links (look within the specific common subdir)
  let l:subdirs = []
  let l:old_subdirs = split(l:url_old, '\/')[:-2]
  let l:new_subdirs = split(l:url_new, '\/')[:-2]
  while !empty(l:old_subdirs)
        \ && !empty(l:new_subdirs)
        \ && l:old_subdirs[0] ==# l:new_subdirs[0]
    call add(l:subdirs, remove(l:old_subdirs, 0))
    call remove(l:new_subdirs, 0)
  endwhile
  if !empty(l:subdirs)
    let l:root .= '/' .. join(l:subdirs, '/')
    let l:url_pairs += [[
          \ wiki#paths#to_wiki_url(a:path_old, l:root),
          \ wiki#paths#to_wiki_url(a:path_new, l:root)
          \]]
  endif

  " Create pattern to match relevant old link urls
  let l:replacement_patterns = []
  for [l:url_old, l:url_new] in l:url_pairs
    let l:re_url_old = '(\.\/|\/)?\zs' .. escape(l:url_old, '.')
    let l:pattern = '\v' .. join([
          \ '\[\[' .. l:re_url_old .. '\ze%(#.*)?%(\|.*)?\]\]',
          \ '\[\[' .. l:re_url_old .. '\ze%(#.*)?\]\[.*\]\]',
          \ '\[.*\]\(' .. l:re_url_old .. '\ze%(#.*)?\)',
          \ '\[.*\]\[' .. l:re_url_old .. '\ze%(#.*)?\]',
          \ '\[' .. l:re_url_old .. '\ze%(#.*)?\]\[\]',
          \ '\<\<' .. l:re_url_old .. '\ze#,[^>]{-}\>\>',
          \], '|')
    let l:replacement_patterns += [[l:pattern, l:url_new]]
  endfor

  return l:replacement_patterns
endfunction

" }}}1

function! s:export(start, end, cfg) abort " {{{1
  let l:fwiki = expand('%:p') .. '.tmp'

  " Parse wiki page content
  let l:lines = getline(a:start, a:end)
  if a:cfg.link_ext_replace
    call s:convert_links_to_html(l:lines)
  endif

  let l:wiki_link_rx = '\[\[#\?\([^\\|\]]\{-}\)\]\]'
  let l:wiki_link_text_rx = '\[\[[^\]]\{-}|\([^\]]\{-}\)\]\]'
  call map(l:lines, 'substitute(v:val, l:wiki_link_rx, ''\1'', ''g'')')
  call map(l:lines, 'substitute(v:val, l:wiki_link_text_rx, ''\1'', ''g'')')
  call writefile(l:lines, l:fwiki, 's')

  " Construct pandoc command
  let l:cmd = printf('pandoc %s -f %s -o %s %s',
        \ a:cfg.args,
        \ a:cfg.from_format,
        \ wiki#u#shellescape(a:cfg.fname),
        \ wiki#u#shellescape(l:fwiki))

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
  let l:creator = wiki#link#get_creator()

  if l:creator.link_type ==# 'md'
    let l:rx = '\[\([^\\\[\]]\{-}\)\]'
          \ .. '(\([^\(\)\\]\{-}\)' .. l:creator.url_extension
          \ .. '\(#[^#\(\)\\]\{-}\)\{-})'
    let l:sub = '[\1](\2.html\3)'
  elseif l:creator.link_type ==# 'wiki'
    let l:rx = '\[\[\([^\\\[\]]\{-}\)' .. l:creator.url_extension
          \ .. '\(#[^#\\\[\]]\{-}\)'
          \ .. '|\([^\[\]\\]\{-}\)\]\]'
    let l:sub = '\[\[\1.html\2|\3\]\]'
  elseif l:creator.link_type ==# 'org'
    let l:rx = '\[\[\([^\\\[\]]\{-}\)' .. l:creator.url_extension
          \ .. '\(#[^#\\\[\]]\{-}\)'
          \ .. '\]\[\([^\[\]\\]\{-}\)\]\]'
    let l:sub = '\[\[\1.html\2|\3\]\]'
  else
    return wiki#log#error(
          \ 'g:wiki_link_creator link_type must be `wiki`, `md`, or `org` to',
          \ 'replace link extensions on export.'
          \)
  endif

  call map(a:lines, {_, x -> substitute(x, l:rx, l:sub, 'g') })
endfunction

" }}}1
