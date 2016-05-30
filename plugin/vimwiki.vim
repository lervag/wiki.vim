if exists("g:loaded_vimwiki") | finish | endif
let g:loaded_vimwiki = 1

let s:old_cpo = &cpo
set cpo&vim

command! -count=1 VimwikiIndex              call vimwiki#base#goto_index(v:count1)
command! -count=1 VimwikiMakeDiaryNote      call vimwiki#diary#make_note(v:count1)

nnoremap <silent><unique> <leader>ww         :VimwikiIndex<CR>
nnoremap <silent><unique> <leader>w<leader>w :VimwikiMakeDiaryNote<CR>

augroup vimwiki
  autocmd!
  autocmd BufEnter           *.wiki call s:setup_buffer_reenter()
  autocmd BufWinEnter        *.wiki call s:setup_buffer_enter()
  autocmd BufLeave,BufHidden *.wiki call s:setup_buffer_leave()
augroup END

"
" Callback functions
"
if !exists("*VimwikiLinkConverter") "{{{1
  function VimwikiLinkConverter(url, source, target)
    return ''
  endfunction
endif

" }}}1
if !exists("*VimwikiWikiIncludeHandler") "{{{1
  function! VimwikiWikiIncludeHandler(value)
    return ''
  endfunction
endif

" }}}1

"
" Functions for options
"
function! VimwikiGetOptionNames() "{{{
  return keys(s:vimwiki_defaults)
endfunction

"}}}
function! VimwikiGetOptions(...) "{{{
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1
  let option_dict = {}
  for kk in keys(s:vimwiki_defaults)
    let option_dict[kk] = VimwikiGet(kk, idx)
  endfor
  return option_dict
endfunction

"}}}
function! VimwikiGet(option, ...) "{{{
  " Return value of option for current wiki or if second parameter exists for
  "   wiki with a given index.
  " If the option is not found, it is assumed to have been previously cached in a
  "   buffer local dictionary, that acts as a cache.
  " If the option is not found in the buffer local dictionary, an error is thrown
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1

  if has_key(g:vimwiki_list[idx], a:option)
    let val = g:vimwiki_list[idx][a:option]
  elseif has_key(s:vimwiki_defaults, a:option)
    let val = s:vimwiki_defaults[a:option]
    let g:vimwiki_list[idx][a:option] = val
  else
    let val = b:vimwiki_list[a:option]
  endif

  " XXX no call to vimwiki#base here or else the whole autoload/base gets loaded!
  return val
endfunction

"}}}
function! VimwikiSet(option, value, ...) "{{{
  " Set option for current wiki or if third parameter exists for
  "   wiki with a given index.
  " If the option is not found or recognized (i.e. does not exist in
  "   s:vimwiki_defaults), it is saved in a buffer local dictionary, that acts
  "   as a cache.
  " If the option is not found in the buffer local dictionary, an error is thrown
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1

  if has_key(s:vimwiki_defaults, a:option) ||
        \ has_key(g:vimwiki_list[idx], a:option)
    let g:vimwiki_list[idx][a:option] = a:value
  elseif exists('b:vimwiki_list')
    let b:vimwiki_list[a:option] = a:value
  else
    let b:vimwiki_list = {}
    let b:vimwiki_list[a:option] = a:value
  endif
endfunction

"}}}
function! VimwikiClear(option, ...) "{{{
  " Clear option for current wiki or if second parameter exists for
  "   wiki with a given index.
  " Currently, only works if option was previously saved in the buffer local
  "   dictionary, that acts as a cache.
  let idx = a:0 == 0 ? g:vimwiki_current_idx : a:1

  if exists('b:vimwiki_list') && has_key(b:vimwiki_list, a:option)
    call remove(b:vimwiki_list, a:option)
  endif
endfunction

"}}}
function! Validate_wiki_options(idx) " {{{1
  call VimwikiSet('path', s:normalize_path(VimwikiGet('path', a:idx)), a:idx)
  call VimwikiSet('path_html', s:normalize_path(s:path_html(a:idx)), a:idx)
  call VimwikiSet('template_path',
        \ s:normalize_path(VimwikiGet('template_path', a:idx)), a:idx)
  call VimwikiSet('diary_rel_path',
        \ s:normalize_path(VimwikiGet('diary_rel_path', a:idx)), a:idx)
endfunction

" }}}1

"
" Helper functions
"
function! s:default(varname, value) "{{{
  if !exists('g:vimwiki_'.a:varname)
    let g:vimwiki_{a:varname} = a:value
  endif
endfunction

"}}}
function! s:path_html(idx) "{{{
  let path_html = VimwikiGet('path_html', a:idx)
  if !empty(path_html)
    return path_html
  else
    let path = VimwikiGet('path', a:idx)
    return substitute(path, '[/\\]\+$', '', '').'_html/'
  endif
endfunction

"}}}
function! s:normalize_path(path) "{{{
  " resolve doesn't work quite right with symlinks ended with / or \
  let path = substitute(a:path, '[/\\]\+$', '', '')
  if path !~# '^scp:'
    return resolve(expand(path)).'/'
  else
    return path.'/'
  endif
endfunction

"}}}
function! s:setup_buffer_leave() "{{{
  if &filetype ==? 'vimwiki'
    " cache global vars of current state XXX: SLOW!?
    call vimwiki#base#cache_buffer_state()
  endif

  let &autowriteall = s:vimwiki_autowriteall
endfunction

"}}}
function! s:setup_buffer_enter() "{{{
  if !vimwiki#base#recall_buffer_state()
    " Find what wiki current buffer belongs to.
    " If wiki does not exist in g:vimwiki_list -- add new wiki there with
    " buffer's path and ext.
    " Else set g:vimwiki_current_idx to that wiki index.
    let path = expand('%:p:h')
    let idx = vimwiki#base#find_wiki(path)

    " The buffer's file is not in the path and user *does NOT* want his wiki
    " extension to be global -- Do not add new wiki.
    if idx == -1 && g:vimwiki_global_ext == 0
      return
    endif

    " initialize and cache global vars of current state
    call vimwiki#base#setup_buffer_state(idx)

  endif

  " If you have
  "     au GUIEnter * VimwikiIndex
  " Then change it to
  "     au GUIEnter * nested VimwikiIndex
  if &filetype == ''
    set filetype=vimwiki
  elseif &syntax ==? 'vimwiki'
    " to force a rescan of the filesystem which may have changed
    " and update VimwikiLinks syntax group that depends on it;
    " b:vimwiki_fs_rescan indicates that setup_filetype() has not been run
    if exists("b:vimwiki_fs_rescan") && VimwikiGet('maxhi')
      set syntax=vimwiki
    endif
    let b:vimwiki_fs_rescan = 1
  endif

  " And conceal level too.
  if g:vimwiki_conceallevel && exists("+conceallevel")
    let &conceallevel = g:vimwiki_conceallevel
  endif
endfunction

"}}}
function! s:setup_buffer_reenter() "{{{
  if !vimwiki#base#recall_buffer_state()
    " Do not repeat work of s:setup_buffer_enter() and s:setup_filetype()
    " Once should be enough ...
  endif
  if !exists("s:vimwiki_autowriteall")
    let s:vimwiki_autowriteall = &autowriteall
  endif
  let &autowriteall = g:vimwiki_autowriteall
endfunction

"}}}

"
" Default options
"
call s:default('list', [])
call s:default('use_mouse', 0)
call s:default('folding', '')
call s:default('global_ext', 1)
call s:default('ext2syntax', {}) " syntax map keyed on extension
call s:default('hl_headers', 0)
call s:default('hl_cb_checked', 0)
call s:default('list_ignore_newline', 1)
call s:default('listsyms', ' .oOX')
call s:default('use_calendar', 1)
call s:default('table_mappings', 1)
call s:default('table_auto_fmt', 1)
call s:default('w32_dir_enc', '')
call s:default('CJK_length', 0)
call s:default('dir_link', '')
call s:default('valid_html_tags', 'b,i,s,u,sub,sup,kbd,br,hr,div,center,strong,em')
call s:default('user_htmls', '')
call s:default('autowriteall', 1)
call s:default('toc_header', 'Contents')
call s:default('html_header_numbering', 0)
call s:default('html_header_numbering_sym', '')
call s:default('conceallevel', 2)
call s:default('url_maxsave', 15)
call s:default('diary_months',
      \ {
      \ 1: 'January', 2: 'February', 3: 'March',
      \ 4: 'April', 5: 'May', 6: 'June',
      \ 7: 'July', 8: 'August', 9: 'September',
      \ 10: 'October', 11: 'November', 12: 'December'
      \ })

call s:default('map_prefix', '<Leader>w')
call s:default('current_idx', 0)
call s:default('auto_chdir', 0)

" Scheme regexes should be defined even if syntax file is not loaded yet
" cause users should be able to <leader>w<leader>w without opening any
" vimwiki file first
" Scheme regexes {{{
call s:default('schemes', 'wiki\d\+,diary,local')
call s:default('web_schemes1', 'http,https,file,ftp,gopher,telnet,nntp,ldap,'.
        \ 'rsync,imap,pop,irc,ircs,cvs,svn,svn+ssh,git,ssh,fish,sftp')
call s:default('web_schemes2', 'mailto,news,xmpp,sip,sips,doi,urn,tel')

let s:rxSchemes = '\%('.
      \ join(split(g:vimwiki_schemes, '\s*,\s*'), '\|').'\|'.
      \ join(split(g:vimwiki_web_schemes1, '\s*,\s*'), '\|').'\|'.
      \ join(split(g:vimwiki_web_schemes2, '\s*,\s*'), '\|').
      \ '\)'

call s:default('rxSchemeUrl', s:rxSchemes.':.*')
call s:default('rxSchemeUrlMatchScheme', '\zs'.s:rxSchemes.'\ze:.*')
call s:default('rxSchemeUrlMatchUrl', s:rxSchemes.':\zs.*\ze')
" scheme regexes }}}

"
" Wiki defaults
"
let s:vimwiki_defaults = {}
let s:vimwiki_defaults.path = '~/vimwiki/'
let s:vimwiki_defaults.path_html = ''   " '' is replaced by derived path.'_html/'
let s:vimwiki_defaults.css_name = 'style.css'
let s:vimwiki_defaults.index = 'index'
let s:vimwiki_defaults.ext = '.wiki'
let s:vimwiki_defaults.maxhi = 0
let s:vimwiki_defaults.syntax = 'default'
let s:vimwiki_defaults.template_path = '~/vimwiki/templates/'
let s:vimwiki_defaults.template_default = 'default'
let s:vimwiki_defaults.template_ext = '.tpl'
let s:vimwiki_defaults.nested_syntaxes = {}
let s:vimwiki_defaults.automatic_nested_syntaxes = 1
let s:vimwiki_defaults.auto_export = 0
let s:vimwiki_defaults.auto_toc = 0
let s:vimwiki_defaults.temp = 0
let s:vimwiki_defaults.diary_rel_path = 'diary/'
let s:vimwiki_defaults.diary_index = 'diary'
let s:vimwiki_defaults.diary_header = 'Diary'
let s:vimwiki_defaults.diary_sort = 'desc'
let s:vimwiki_defaults.diary_link_fmt = '%Y-%m-%d'
let s:vimwiki_defaults.custom_wiki2html = ''
let s:vimwiki_defaults.list_margin = -1
let s:vimwiki_defaults.auto_tags = 0

let &cpo = s:old_cpo
