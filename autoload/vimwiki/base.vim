" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#base#file_pattern(files) " {{{1
  return '\V\%('.join(a:files, '\|').'\)\m'
endfunction

" }}}1
function! vimwiki#base#current_subdir() " {{{1
  return vimwiki#todo#subdir(vimwiki#opts#get('path'), expand('%:p'))
endfunction

" }}}1
function! vimwiki#base#invsubdir(subdir) " {{{1
  return substitute(a:subdir, '[^/\.]\+/', '../', 'g')
endfunction

" }}}1
function! vimwiki#base#find_wiki(path) " {{{1
  " Returns: the number of the wiki a file belongs to
  let path = vimwiki#path#path_norm(vimwiki#path#chomp_slash(a:path))
  let idx = 0
  while idx < len(g:vimwiki_list)
    let idx_path = expand(vimwiki#opts#get('path', idx))
    let idx_path = vimwiki#path#path_norm(vimwiki#path#chomp_slash(idx_path))
    if vimwiki#path#is_equal(
          \ vimwiki#path#path_common_pfx(idx_path, path), idx_path)
      return idx
    endif
    let idx += 1
  endwhile

  " an orphan page has been detected
  return -1
endfunction

" }}}1
function! vimwiki#base#resolve_link(link_text, ...) " {{{1
  " THE central function of Vimwiki. Extract infos about the target from a link.
  " If the second parameter is present, which should be an absolute file path, it
  " is assumed that the link appears in that file. Without it, the current file
  " is used.
  if a:0
    let source_wiki = vimwiki#base#find_wiki(a:1)
    let source_file = a:1
  else
    let source_wiki = g:vimwiki_current_idx
    let source_file = expand('%:p')
  endif

  let link_text = a:link_text

  " if link is schemeless add wikiN: scheme
  if link_text !~# g:vimwiki_rxSchemeUrl
    let link_text = 'wiki'.source_wiki.':'.link_text
  endif


  let link_infos = {
        \ 'index': -1,
        \ 'scheme': '',
        \ 'filename': '',
        \ 'anchor': '',
        \ }


  " extract scheme
  let link_infos.scheme = matchstr(link_text, g:vimwiki_rxSchemeUrlMatchScheme)
  if link_infos.scheme == '' || link_text == ''
    let link_infos.filename = ''   " malformed link
    return link_infos
  endif
  if link_infos.scheme !~# '\mwiki\d\+\|diary\|local\|file'
    let link_infos.filename = link_text  " unknown scheme, may be a weblink
    return link_infos
  endif
  let link_text = matchstr(link_text, g:vimwiki_rxSchemeUrlMatchUrl)

  let is_wiki_link = link_infos.scheme =~# '\mwiki\d\+' ||
        \ link_infos.scheme ==# 'diary'

  " extract anchor
  if is_wiki_link
    let split_lnk = split(link_text, '#', 1)
    let link_text = split_lnk[0]
    if len(split_lnk) > 1 && split_lnk[-1] != ''
      let link_infos.anchor = join(split_lnk[1:], '#')
    endif
    if link_text == ''  " because the link was of the form '#anchor'
      let link_text = fnamemodify(source_file, ':p:t:r')
    endif
  endif

  " check if absolute or relative path
  if is_wiki_link && link_text[0] == '/'
    if link_text != '/'
      let link_text = link_text[1:]
    endif
    let is_relative = 0
  elseif !is_wiki_link && vimwiki#path#is_absolute(link_text)
    let is_relative = 0
  else
    let is_relative = 1
    let root_dir = fnamemodify(source_file, ':p:h') . '/'
  endif


  " extract the other items depending on the scheme
  if link_infos.scheme =~# '\mwiki\d\+'
    let link_infos.index = eval(matchstr(link_infos.scheme, '\D\+\zs\d\+\ze'))
    if link_infos.index < 0 || link_infos.index >= len(g:vimwiki_list)
      let link_infos.filename = ''
      return link_infos
    endif

    if !is_relative || link_infos.index != source_wiki
      let root_dir = vimwiki#opts#get('path', link_infos.index)
    endif

    let link_infos.filename = root_dir . link_text

    if vimwiki#path#is_link_to_dir(link_text)
      if g:vimwiki_dir_link != ''
        let link_infos.filename .= g:vimwiki_dir_link .
              \ vimwiki#opts#get('ext', link_infos.index)
      endif
    else
      let link_infos.filename .= vimwiki#opts#get('ext', link_infos.index)
    endif

  elseif link_infos.scheme ==# 'diary'
    let link_infos.index = source_wiki

    let link_infos.filename =
          \ vimwiki#opts#get('path', link_infos.index) .
          \ vimwiki#opts#get('diary_rel_path', link_infos.index) .
          \ link_text .
          \ vimwiki#opts#get('ext', link_infos.index)
  elseif (link_infos.scheme ==# 'file' || link_infos.scheme ==# 'local')
        \ && is_relative
    let link_infos.filename = simplify(root_dir . link_text)
  else " absolute file link
    " collapse repeated leading "/"'s within a link
    let link_text = substitute(link_text, '\m^/\+', '/', '')
    " expand ~/
    let link_text = fnamemodify(link_text, ':p')
    let link_infos.filename = simplify(link_text)
  endif

  let link_infos.filename = vimwiki#path#normalize(link_infos.filename)
  return link_infos
endfunction

" }}}1
function! vimwiki#base#system_open_link(url) " {{{1
  call system('xdg-open ' . shellescape(a:url).' &')
endfunction

" }}}1
function! vimwiki#base#get_globlinks_escaped() abort "{{{only get links from the current dir
  " change to the directory of the current file
  let orig_pwd = getcwd()
  lcd! %:h
  " all path are relative to the current file's location
  let globlinks = glob('*'.vimwiki#opts#get('ext'),1)."\n"
  " remove extensions
  let globlinks = substitute(globlinks, '\'.vimwiki#opts#get('ext').'\ze\n', '', 'g')
  " restore the original working directory
  exe 'lcd! '.orig_pwd
  " convert to a List
  let lst = split(globlinks, '\n')
  " Apply fnameescape() to each item
  call map(lst, 'fnameescape(v:val)')
  " Convert back to newline-separated list
  let globlinks = join(lst, "\n")
  " return all escaped links as a single newline-separated string
  return globlinks
endfunction

" }}}1
function! vimwiki#base#generate_links() " {{{1
  let lines = []

  let links = vimwiki#base#get_wikilinks(g:vimwiki_current_idx, 0)
  call sort(links)

  let bullet = repeat(' ', vimwiki#lst#get_list_margin()).
        \ vimwiki#lst#default_symbol().' '
  for link in links
    let abs_filepath = vimwiki#path#abs_path_of_link(link)
    if !s:is_diary_file(abs_filepath)
      call add(lines, bullet.
            \ substitute(g:vimwiki_WikiLinkTemplate1, '__LinkUrl__', '\='."'".link."'", ''))
    endif
  endfor

  let links_rx = '\m^\s*'.vimwiki#u#escape(vimwiki#lst#default_symbol()).' '

  call vimwiki#base#update_listing_in_buffer(lines, 'Generated Links', links_rx,
        \ line('$')+1, 1)
endfunction

" }}}1
function! vimwiki#base#goto(...) " {{{1
  let key = a:1
  let anchor = a:0 > 1 ? a:2 : ''

  call vimwiki#todo#edit_file(':e',
        \ vimwiki#opts#get('path') . key . vimwiki#opts#get('ext'),
        \ anchor)
endfunction

" }}}1
function! vimwiki#base#find_files(wiki_nr, directories_only) " {{{1
  " Returns: a list containing all files of the given wiki as absolute file path.
  " If the given wiki number is negative, the diary of the current wiki is used
  " If the second argument is not zero, only directories are found
  let wiki_nr = a:wiki_nr
  if wiki_nr >= 0
    let root_directory = vimwiki#opts#get('path', wiki_nr)
  else
    let root_directory = vimwiki#opts#get('path').vimwiki#opts#get('diary_rel_path')
    let wiki_nr = g:vimwiki_current_idx
  endif
  if a:directories_only
    let ext = '/'
  else
    let ext = vimwiki#opts#get('ext', wiki_nr)
  endif
  " if current wiki is temporary -- was added by an arbitrary wiki file then do
  " not search wiki files in subdirectories. Or it would hang the system if
  " wiki file was created in $HOME or C:/ dirs.
  if vimwiki#opts#get('temp', wiki_nr)
    let pattern = '*'.ext
  else
    let pattern = '**/*'.ext
  endif
  return split(globpath(root_directory, pattern), '\n')
endfunction

" }}}1
function! vimwiki#base#get_wikilinks(wiki_nr, also_absolute_links) " {{{1
  " Returns: a list containing the links to get from the current file to all wiki
  " files in the given wiki.
  " If the given wiki number is negative, the diary of the current wiki is used.
  " If also_absolute_links is nonzero, also return links of the form /file
  let files = vimwiki#base#find_files(a:wiki_nr, 0)
  if a:wiki_nr == g:vimwiki_current_idx
    let cwd = vimwiki#path#wikify_path(expand('%:p:h'))
  elseif a:wiki_nr < 0
    let cwd = vimwiki#opts#get('path').vimwiki#opts#get('diary_rel_path')
  else
    let cwd = vimwiki#opts#get('path', a:wiki_nr)
  endif
  let result = []
  for wikifile in files
    let wikifile = fnamemodify(wikifile, ':r') " strip extension
    let wikifile = vimwiki#path#relpath(cwd, wikifile)
    call add(result, wikifile)
  endfor
  if a:also_absolute_links
    for wikifile in files
      if a:wiki_nr == g:vimwiki_current_idx
        let cwd = vimwiki#opts#get('path')
      elseif a:wiki_nr < 0
        let cwd = vimwiki#opts#get('path').vimwiki#opts#get('diary_rel_path')
      endif
      let wikifile = fnamemodify(wikifile, ':r') " strip extension
      let wikifile = '/'.vimwiki#path#relpath(cwd, wikifile)
      call add(result, wikifile)
    endfor
  endif
  return result
endfunction

" }}}1
function! vimwiki#base#get_wiki_directories(wiki_nr) " {{{1
  " Returns: a list containing the links to all directories from the current file
  let dirs = vimwiki#base#find_files(a:wiki_nr, 1)
  if a:wiki_nr == g:vimwiki_current_idx
    let cwd = vimwiki#path#wikify_path(expand('%:p:h'))
    let root_dir = vimwiki#opts#get('path')
  else
    let cwd = vimwiki#opts#get('path', a:wiki_nr)
  endif
  let result = ['./']
  for wikidir in dirs
    let wikidir_relative = vimwiki#path#relpath(cwd, wikidir)
    call add(result, wikidir_relative)
    if a:wiki_nr == g:vimwiki_current_idx
      let wikidir_absolute = '/'.vimwiki#path#relpath(root_dir, wikidir)
      call add(result, wikidir_absolute)
    endif
  endfor
  return result
endfunction

" }}}1
function! vimwiki#base#get_anchors(filename, syntax) " {{{1
  if !filereadable(a:filename)
    return []
  endif

  let rxheader = g:vimwiki_{a:syntax}_header_search
  let rxbold = g:vimwiki_{a:syntax}_bold_search
  let rxtag = g:vimwiki_{a:syntax}_tag_search

  let anchor_level = ['', '', '', '', '', '', '']
  let anchors = []
  let current_complete_anchor = ''
  for line in readfile(a:filename)

    " collect headers
    let h_match = matchlist(line, rxheader)
    if !empty(h_match)
      let header = vimwiki#u#trim(h_match[2])
      let level = len(h_match[1])
      call add(anchors, header)
      let anchor_level[level-1] = header
      for l in range(level, 6)
        let anchor_level[l] = ''
      endfor
      if level == 1
        let current_complete_anchor = header
      else
        let current_complete_anchor = ''
        for l in range(level-1)
          if anchor_level[l] != ''
            let current_complete_anchor .= anchor_level[l].'#'
          endif
        endfor
        let current_complete_anchor .= header
        call add(anchors, current_complete_anchor)
      endif
    endif

    " collect bold text (there can be several in one line)
    let bold_count = 1
    while 1
      let bold_text = matchstr(line, rxbold, 0, bold_count)
      if bold_text == ''
        break
      endif
      call add(anchors, bold_text)
      if current_complete_anchor != ''
        call add(anchors, current_complete_anchor.'#'.bold_text)
      endif
      let bold_count += 1
    endwhile

    " collect tags text (there can be several in one line)
    let tag_count = 1
    while 1
      let tag_group_text = matchstr(line, rxtag, 0, tag_count)
      if tag_group_text == ''
        break
      endif
      for tag_text in split(tag_group_text, ':')
        call add(anchors, tag_text)
        if current_complete_anchor != ''
          call add(anchors, current_complete_anchor.'#'.tag_text)
        endif
      endfor
      let tag_count += 1
    endwhile

  endfor

  return anchors
endfunction

" }}}1
function! vimwiki#base#search_word(wikiRx, cmd) " {{{1
  let match_line = search(a:wikiRx, 's'.a:cmd)
  if match_line == 0
    echomsg 'Vimwiki: Wiki link not found'
  endif
endfunction

" }}}1
function! vimwiki#base#matchstr_at_cursor(wikiRX) " {{{1
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    return strpart(line, ebeg, elen)
  else
    return ""
  endif
endf "}}}
function! vimwiki#base#replacestr_at_cursor(wikiRX, sub) " {{{1
  let col = col('.') - 1
  let line = getline('.')
  let ebeg = -1
  let cont = match(line, a:wikiRX, 0)
  while (ebeg >= 0 || (0 <= cont) && (cont <= col))
    let contn = matchend(line, a:wikiRX, cont)
    if (cont <= col) && (col < contn)
      let ebeg = match(line, a:wikiRX, cont)
      let elen = contn - ebeg
      break
    else
      let cont = match(line, a:wikiRX, contn)
    endif
  endwh
  if ebeg >= 0
    " TODO: There might be problems with Unicode chars...
    let newline = strpart(line, 0, ebeg).a:sub.strpart(line, ebeg+elen)
    call setline(line('.'), newline)
  endif
endf "}}}
function! vimwiki#base#nested_syntax(filetype, start, end, textSnipHl) abort "{{{
  " From http://vim.wikia.com/wiki/VimTip857
  let ft=toupper(a:filetype)
  let group='textGroup'.ft
  if exists('b:current_syntax')
    let s:current_syntax=b:current_syntax
    " Remove current syntax definition, as some syntax files (e.g. cpp.vim)
    " do nothing if b:current_syntax is defined.
    unlet b:current_syntax
  endif

  " Some syntax files set up iskeyword which might scratch vimwiki a bit.
  " Let us save and restore it later.
  " let b:skip_set_iskeyword = 1
  let is_keyword = &iskeyword

  try
    " keep going even if syntax file is not found
    execute 'syntax include @'.group.' syntax/'.a:filetype.'.vim'
    execute 'syntax include @'.group.' after/syntax/'.a:filetype.'.vim'
  catch
  endtry

  let &iskeyword = is_keyword

  if exists('s:current_syntax')
    let b:current_syntax=s:current_syntax
  else
    unlet b:current_syntax
  endif
  execute 'syntax region textSnip'.ft.
        \ ' matchgroup='.a:textSnipHl.
        \ ' start="'.a:start.'" end="'.a:end.'"'.
        \ ' contains=@'.group.' keepend'

  " A workaround to Issue 115: Nested Perl syntax highlighting differs from
  " regular one.
  " Perl syntax file has perlFunctionName which is usually has no effect due to
  " 'contained' flag. Now we have 'syntax include' that makes all the groups
  " included as 'contained' into specific group.
  " Here perlFunctionName (with quite an angry regexp "\h\w*[^:]") clashes with
  " the rest syntax rules as now it has effect being really 'contained'.
  " Clear it!
  if ft =~? 'perl'
    syntax clear perlFunctionName
  endif
endfunction

" }}}1
function! vimwiki#base#update_listing_in_buffer(strings, start_header, content_regex, default_lnum, create) " {{{1
  " apparently, Vim behaves strange when files change while in diff mode
  if &diff || &readonly
    return
  endif

  " check if the listing is already there
  let already_there = 0

  let header_rx = '\m^\s*'.
        \ substitute(g:vimwiki_rxH1_Template, '__Header__', a:start_header, '')
        \ .'\s*$'

  let start_lnum = 1
  while start_lnum <= line('$')
    if getline(start_lnum) =~# header_rx
      let already_there = 1
      break
    endif
    let start_lnum += 1
  endwhile

  if !already_there && !a:create
    return
  endif

  let winview_save = winsaveview()
  let cursor_line = winview_save.lnum
  let is_cursor_after_listing = 0

  let is_fold_closed = 1

  let lines_diff = 0

  if already_there
    let is_fold_closed = ( foldclosed(start_lnum) > -1 )
    " delete the old listing
    let whitespaces_in_first_line = matchstr(getline(start_lnum), '\m^\s*')
    let end_lnum = start_lnum + 1
    while end_lnum <= line('$') && getline(end_lnum) =~# a:content_regex
      let end_lnum += 1
    endwhile
    let is_cursor_after_listing = ( cursor_line >= end_lnum )
    " We'll be removing a range.  But, apparently, if folds are enabled, Vim
    " won't let you remove a range that overlaps with closed fold -- the entire
    " fold gets deleted.  So we temporarily disable folds, and then reenable
    " them right back.
    let foldenable_save = &l:foldenable
    setlo nofoldenable
    silent exe start_lnum.','.string(end_lnum - 1).'delete _'
    let &l:foldenable = foldenable_save
    let lines_diff = 0 - (end_lnum - start_lnum)
  else
    let start_lnum = a:default_lnum
    let is_cursor_after_listing = ( cursor_line > a:default_lnum )
    let whitespaces_in_first_line = ''
  endif

  let start_of_listing = start_lnum

  " write new listing
  let new_header = whitespaces_in_first_line
        \ . substitute(g:vimwiki_rxH1_Template,
        \ '__Header__', '\='."'".a:start_header."'", '')
  call append(start_lnum - 1, new_header)
  let start_lnum += 1
  let lines_diff += 1 + len(a:strings)
  for string in a:strings
    call append(start_lnum - 1, string)
    let start_lnum += 1
  endfor
  " append an empty line if there is not one
  if start_lnum <= line('$') && getline(start_lnum) !~# '\m^\s*$'
    call append(start_lnum - 1, '')
    let lines_diff += 1
  endif

  " Open fold, if needed
  if !is_fold_closed && ( foldclosed(start_of_listing) > -1 )
    exe start_of_listing
    norm! zo
  endif

  if is_cursor_after_listing
    let winview_save.lnum += lines_diff
  endif
  call winrestview(winview_save)
endfunction

" }}}1
function! vimwiki#base#apply_template(template, rxUrl, rxDesc, rxStyle) " {{{1
  let lnk = a:template
  if a:rxUrl != ""
    let lnk = substitute(lnk, '__LinkUrl__', '\='."'".a:rxUrl."'", 'g')
  endif
  if a:rxDesc != ""
    let lnk = substitute(lnk, '__LinkDescription__', '\='."'".a:rxDesc."'", 'g')
  endif
  if a:rxStyle != ""
    let lnk = substitute(lnk, '__LinkStyle__', '\='."'".a:rxStyle."'", 'g')
  endif
  return lnk
endfunction

" }}}1
function! vimwiki#base#normalize_link_helper(str, rxUrl, rxDesc, template) " {{{1
  let str = a:str
  let url = matchstr(str, a:rxUrl)
  let descr = matchstr(str, a:rxDesc)
  let template = a:template
  if descr == ""
    let descr = s:clean_url(url)
  endif
  let lnk = substitute(template, '__LinkDescription__', '\="'.descr.'"', '')
  let lnk = substitute(lnk, '__LinkUrl__', '\="'.url.'"', '')
  return lnk
endfunction

" }}}1
function! vimwiki#base#normalize_imagelink_helper(str, rxUrl, rxDesc, rxStyle, template) " {{{1
  let lnk = vimwiki#base#normalize_link_helper(a:str, a:rxUrl, a:rxDesc, a:template)
  let style = matchstr(a:str, a:rxStyle)
  let lnk = substitute(lnk, '__LinkStyle__', '\="'.style.'"', '')
  return lnk
endfunction

" }}}1
function! vimwiki#base#detect_nested_syntax() " {{{1
  let last_word = '\v.*<(\w+)\s*$'
  let lines = map(filter(getline(1, "$"), 'v:val =~ "```" && v:val =~ last_word'),
        \ 'substitute(v:val, last_word, "\\=submatch(1)", "")')
  let dict = {}
  for elem in lines
    let dict[elem] = elem
  endfor
  return dict
endfunction

" }}}1

function! vimwiki#base#complete_links_escaped(ArgLead, CmdLine, CursorPos) abort " {{{1
  " We can safely ignore args if we use -custom=complete option, Vim engine
  " will do the job of filtering.
  return vimwiki#base#get_globlinks_escaped()
endfunction

" }}}1
function! vimwiki#base#AddHeaderLevel() " {{{1
  let lnum = line('.')
  let line = getline(lnum)
  let rxHdr = g:vimwiki_rxH
  if line =~# '^\s*$'
    return
  endif

  if line =~# g:vimwiki_rxHeader
    let level = vimwiki#u#count_first_sym(line)
    if level < 6
      if g:vimwiki_symH
        let line = substitute(line, '\('.rxHdr.'\+\).\+\1', rxHdr.'&'.rxHdr, '')
      else
        let line = substitute(line, '\('.rxHdr.'\+\).\+', rxHdr.'&', '')
      endif
      call setline(lnum, line)
    endif
  else
    let line = substitute(line, '^\s*', '&'.rxHdr.' ', '')
    if g:vimwiki_symH
      let line = substitute(line, '\s*$', ' '.rxHdr.'&', '')
    endif
    call setline(lnum, line)
  endif
endfunction

" }}}1
function! vimwiki#base#RemoveHeaderLevel() " {{{1
  let lnum = line('.')
  let line = getline(lnum)
  let rxHdr = g:vimwiki_rxH
  if line =~# '^\s*$'
    return
  endif

  if line =~# g:vimwiki_rxHeader
    let level = vimwiki#u#count_first_sym(line)
    let old = repeat(rxHdr, level)
    let new = repeat(rxHdr, level - 1)

    let chomp = line =~# rxHdr.'\s'

    if g:vimwiki_symH
      let line = substitute(line, old, new, 'g')
    else
      let line = substitute(line, old, new, '')
    endif

    if level == 1 && chomp
      let line = substitute(line, '^\s', '', 'g')
      let line = substitute(line, '\s$', '', 'g')
    endif

    let line = substitute(line, '\s*$', '', '')

    call setline(lnum, line)
  endif
endfunction

" }}}1
function! vimwiki#base#ui_select() " {{{1
  call s:print_wiki_list()
  let idx = input("Select Wiki (specify number): ")
  if idx == ""
    return
  endif
  call vimwiki#page#goto_index()
endfunction

" }}}1


function! s:jump_to_anchor(anchor) " {{{1
  let oldpos = getpos('.')
  call cursor(1, 1)

  let anchor = vimwiki#u#escape(a:anchor)

  let segments = split(anchor, '#', 0)
  for segment in segments

    let anchor_header = substitute(
          \ g:vimwiki_markdown_header_match,
          \ '__Header__', "\\='".segment."'", '')
    let anchor_bold = substitute(g:vimwiki_markdown_bold_match,
          \ '__Text__', "\\='".segment."'", '')
    let anchor_tag = substitute(g:vimwiki_markdown_tag_match,
          \ '__Tag__', "\\='".segment."'", '')

    if         !search(anchor_tag, 'Wc')
          \ && !search(anchor_header, 'Wc')
          \ && !search(anchor_bold, 'Wc')
      call setpos('.', oldpos)
      break
    endif
    let oldpos = getpos('.')
  endfor
endfunction

" }}}1
function! s:get_links(wikifile, idx) " {{{1
  if !filereadable(a:wikifile)
    return []
  endif

  let syntax = 'markdown'
  let rx_link = g:vimwiki_{syntax}_wikilink
  let links = []
  let lnum = 0

  for line in readfile(a:wikifile)
    let lnum += 1

    let link_count = 1
    while 1
      let col = match(line, rx_link, 0, link_count)+1
      let link_text = matchstr(line, rx_link, 0, link_count)
      if link_text == ''
        break
      endif
      let link_count += 1
      let target = vimwiki#base#resolve_link(link_text, a:wikifile)
      if target.filename != '' &&
            \ target.scheme =~# '\mwiki\d\+\|diary\|file\|local'
        call add(links, [target.filename, target.anchor, lnum, col])
      endif
    endwhile
  endfor

  return links
endfunction

" }}}1
function! s:print_wiki_list() " {{{1
  let idx = 0
  while idx < len(g:vimwiki_list)
    if idx == g:vimwiki_current_idx
      let sep = ' * '
      echohl PmenuSel
    else
      let sep = '   '
      echohl None
    endif
    echo (idx + 1).sep.vimwiki#opts#get('path', idx)
    let idx += 1
  endwhile
  echohl None
endfunction

" }}}1
function! s:update_wiki_link(fname, old, new) " {{{1
  echo "Updating links in ".a:fname
  let has_updates = 0
  let dest = []
  for line in readfile(a:fname)
    if !has_updates && match(line, a:old) != -1
      let has_updates = 1
    endif
    " XXX: any other characters to escape!?
    call add(dest, substitute(line, a:old, escape(a:new, "&"), "g"))
  endfor
  " add exception handling...
  if has_updates
    call rename(a:fname, a:fname.'#vimwiki_upd#')
    call writefile(dest, a:fname)
    call delete(a:fname.'#vimwiki_upd#')
  endif
endfunction

" }}}1
function! s:update_wiki_links_dir(dir, old_fname, new_fname) " {{{1
  let old_fname = substitute(a:old_fname, '[/\\]', '[/\\\\]', 'g')
  let new_fname = a:new_fname

  let old_fname_r = vimwiki#base#apply_template(
        \ g:vimwiki_WikiLinkMatchUrlTemplate, old_fname, '', '')

  let files = split(glob(vimwiki#opts#get('path').a:dir.'*'.vimwiki#opts#get('ext')), '\n')
  for fname in files
    call s:update_wiki_link(fname, old_fname_r, new_fname)
  endfor
endfunction

" }}}1
function! s:tail_name(fname) " {{{1
  let result = substitute(a:fname, ":", "__colon__", "g")
  let result = fnamemodify(result, ":t:r")
  let result = substitute(result, "__colon__", ":", "g")
  return result
endfunction

" }}}1
function! s:update_wiki_links(old_fname, new_fname) " {{{1
  let old_fname = a:old_fname
  let new_fname = a:new_fname

  let subdirs = split(a:old_fname, '[/\\]')[: -2]

  " TODO: Use Dictionary here...
  let dirs_keys = ['']
  let dirs_vals = ['']
  if len(subdirs) > 0
    let dirs_keys = ['']
    let dirs_vals = [join(subdirs, '/').'/']
    let idx = 0
    while idx < len(subdirs) - 1
      call add(dirs_keys, join(subdirs[: idx], '/').'/')
      call add(dirs_vals, join(subdirs[idx+1 :], '/').'/')
      let idx = idx + 1
    endwhile
    call add(dirs_keys,join(subdirs, '/').'/')
    call add(dirs_vals, '')
  endif

  let idx = 0
  while idx < len(dirs_keys)
    let dir = dirs_keys[idx]
    let new_dir = dirs_vals[idx]
    call s:update_wiki_links_dir(dir,
          \ new_dir.old_fname, new_dir.new_fname)
    let idx = idx + 1
  endwhile
endfunction

" }}}1
function! s:get_wiki_buffers() " {{{1
  let blist = []
  let bcount = 1
  while bcount<=bufnr("$")
    if bufexists(bcount)
      let bname = fnamemodify(bufname(bcount), ":p")
      if bname =~# vimwiki#opts#get('ext')."$"
        let bitem = [bname, getbufvar(bname, "vimwiki_prev_link")]
        call add(blist, bitem)
      endif
    endif
    let bcount = bcount + 1
  endwhile
  return blist
endfunction

" }}}1
function! s:open_wiki_buffer(item) " {{{1
  call vimwiki#todo#edit_file(':e', a:item[0], '')
  if !empty(a:item[1])
    call setbufvar(a:item[0], "vimwiki_prev_link", a:item[1])
  endif
endfunction

" }}}1


function! s:clean_url(url) " {{{1
  let url = split(a:url, '/\|=\|-\|&\|?\|\.')
  let url = filter(url, 'v:val !=# ""')
  let url = filter(url, 'v:val !=# "www"')
  let url = filter(url, 'v:val !=# "com"')
  let url = filter(url, 'v:val !=# "org"')
  let url = filter(url, 'v:val !=# "net"')
  let url = filter(url, 'v:val !=# "edu"')
  let url = filter(url, 'v:val !=# "http\:"')
  let url = filter(url, 'v:val !=# "https\:"')
  let url = filter(url, 'v:val !=# "file\:"')
  let url = filter(url, 'v:val !=# "xml\:"')
  return join(url, " ")
endfunction

" }}}1
function! s:is_diary_file(filename) " {{{1
  let file_path = vimwiki#path#path_norm(a:filename)
  let rel_path = vimwiki#opts#get('diary_rel_path')
  let diary_path = vimwiki#path#path_norm(vimwiki#opts#get('path') . rel_path)
  return rel_path != ''
        \ && file_path =~# '^'.vimwiki#u#escape(diary_path)
endfunction

" }}}1
function! s:normalize_link_in_diary(lnk) " {{{1
  let link = a:lnk . vimwiki#opts#get('ext')
  let link_wiki = vimwiki#opts#get('path') . '/' . link
  let link_diary = vimwiki#opts#get('path') . '/'
        \ . vimwiki#opts#get('diary_rel_path') . '/' . link
  let link_exists_in_diary = filereadable(link_diary)
  let link_exists_in_wiki = filereadable(link_wiki)
  let link_is_date = a:lnk =~# '\d\d\d\d-\d\d-\d\d'

  if ! link_exists_in_wiki || link_exists_in_diary || link_is_date
    let str = a:lnk
    let rxUrl = g:vimwiki_rxWord
    let rxDesc = ''
    let template = g:vimwiki_WikiLinkTemplate1
  else
    let depth = len(split(vimwiki#opts#get('diary_rel_path'), '/'))
    let str = repeat('../', depth) . a:lnk . '|' . a:lnk
    let rxUrl = '^.*\ze|'
    let rxDesc = '|\zs.*$'
    let template = g:vimwiki_WikiLinkTemplate2
  endif

  return vimwiki#base#normalize_link_helper(str, rxUrl, rxDesc, template)
endfunction

" }}}1

" vim: fdm=marker sw=2
