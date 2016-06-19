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

"
" Default options
"
let g:vimwiki_listsyms = ' .oOX'

let g:vimwiki_schemes = 'wiki\d\+,diary,local'
let g:vimwiki_web_schemes1 = 'http,https,file,ftp,gopher,telnet,nntp,ldap,'.
        \ 'rsync,imap,pop,irc,ircs,cvs,svn,svn+ssh,git,ssh,fish,sftp'
let g:vimwiki_web_schemes2 = 'mailto,news,xmpp,sip,sips,doi,urn,tel'

let s:rxSchemes = '\%('.
      \ join(split(g:vimwiki_schemes, '\s*,\s*'), '\|').'\|'.
      \ join(split(g:vimwiki_web_schemes1, '\s*,\s*'), '\|').'\|'.
      \ join(split(g:vimwiki_web_schemes2, '\s*,\s*'), '\|').
      \ '\)'
let g:vimwiki_rxSchemeUrl = s:rxSchemes.':.*'
let g:vimwiki_rxSchemeUrlMatchScheme = '\zs'.s:rxSchemes.'\ze:.*'
let g:vimwiki_rxSchemeUrlMatchUrl = s:rxSchemes.':\zs.*\ze'

let &cpo = s:old_cpo

" vim: fdm=marker sw=2
