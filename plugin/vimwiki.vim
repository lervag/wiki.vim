" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists("g:vimwiki_loaded") | finish | endif
let g:vimwiki_loaded = 1

let s:old_cpo = &cpo
set cpo&vim

nnoremap <silent> <leader>ww         :call vimwiki#page#goto_index()<cr>
nnoremap <silent> <leader>wx         :call vimwiki#reload()<cr>
nnoremap <silent> <leader>w<leader>w :call vimwiki#diary#make_note()<cr>

augroup vimwiki
  autocmd!
  autocmd BufEnter           *.wiki call s:setup_buffer_reenter()
  autocmd BufWinEnter        *.wiki call s:setup_buffer_enter()
  autocmd BufLeave,BufHidden *.wiki call s:setup_buffer_leave()
augroup END

"
" Helper functions
"
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
    call vimwiki#todo#setup_buffer_state(idx)

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
    if exists("b:vimwiki_fs_rescan") && vimwiki#opts#get('maxhi')
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
function! s:default(varname, value)
  if !exists('g:vimwiki_'.a:varname)
    let g:vimwiki_{a:varname} = a:value
  endif
endfunction
call s:default('list', [])
call s:default('global_ext', 1)
call s:default('hl_cb_checked', 0)
call s:default('list_ignore_newline', 1)
call s:default('listsyms', ' .oOX')
call s:default('use_calendar', 1)
call s:default('table_auto_fmt', 1)
call s:default('w32_dir_enc', '')
call s:default('dir_link', '')
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

call vimwiki#opts#set('path', fnamemodify(vimwiki#opts#get('path'), ':p'))
call vimwiki#opts#set('diary_rel_path', vimwiki#opts#get('diary_rel_path') . '/')

let &cpo = s:old_cpo

" vim: fdm=marker sw=2
