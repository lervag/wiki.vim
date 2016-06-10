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
  autocmd BufWinEnter        *.wiki call s:setup_buffer_enter()
  autocmd BufLeave,BufHidden *.wiki call s:setup_buffer_leave()
augroup END

"
" Helper functions
"
function! s:setup_buffer_leave() "{{{
  if &filetype ==? 'vimwiki'
    call vimwiki#base#cache_buffer_state()
  endif
endfunction

"}}}
function! s:setup_buffer_enter() "{{{
  if !vimwiki#base#recall_buffer_state()
    let path = expand('%:p:h')
    let idx = vimwiki#base#find_wiki(path)

    if idx == -1 && g:vimwiki_global_ext == 0
      return
    endif

    " initialize and cache global vars of current state
    call vimwiki#todo#setup_buffer_state(idx)
  endif

  if g:vimwiki_conceallevel && exists("+conceallevel")
    let &conceallevel = g:vimwiki_conceallevel
  endif
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
