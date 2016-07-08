" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" Init functions
"
function! vimwiki#init() " {{{1
  "
  " Require minimum configuration
  "
  if !exists('g:vimwiki') || !exists('g:vimwiki.root')
    echomsg 'Please define g:vimwiki.root!'
    return
  endif

  "
  " Only load the plugin once
  "
  if get(g:vimwiki, 'loaded', 0) | return | endif
  let g:vimwiki.loaded = 1

  "
  " Ensure absolute path
  "
  let g:vimwiki.root = fnamemodify(g:vimwiki.root, ':p')
  let g:vimwiki.diary = g:vimwiki.root . 'journal/'

  "
  " Warn if wiki path is invalid
  "
  if !isdirectory(g:vimwiki.root)
    echomsg 'Please set g:vimwiki.root to a valid wiki path!'
    return
  endif

  "
  " Define mappings
  "
  nnoremap <silent> <leader>ww         :call vimwiki#goto_index()<cr>
  nnoremap <silent> <leader>wx         :call vimwiki#reload()<cr>
  nnoremap <silent> <leader>w<leader>w :call vimwiki#diary#make_note()<cr>
endfunction

" }}}1
function! vimwiki#init_buffer() " {{{1
  setlocal nolisp
  setlocal nomodeline
  setlocal nowrap
  setlocal foldmethod=expr
  setlocal foldexpr=vimwiki#fold#level(v:lnum)
  setlocal foldtext=vimwiki#fold#text()
  setlocal omnifunc=vimwiki#complete#omnicomplete
  setlocal suffixesadd=.wiki
  setlocal isfname-=[,]
  setlocal autoindent
  setlocal nosmartindent
  setlocal nocindent
  setlocal comments =:*\ TODO:,b:*\ [\ ],b:*\ [X],b:*
  setlocal comments+=:-\ TODO:,b:-\ [\ ],b:-\ [X],b:-
  setlocal formatoptions-=o
  setlocal formatoptions+=n
  let &l:formatlistpat = '\v^\s*%(\d|\l|i+)\.\s'

  "
  " Autocommands
  "
  augroup vimwiki
    autocmd!
    autocmd BufWinEnter *.wiki setlocal conceallevel=2
  augroup END

  let b:vimwiki = {
        \ 'in_diary' : stridx(
        \   resolve(expand('%:p')),
        \   resolve(g:vimwiki.diary)) == 0
        \ }

  let g:vimwiki_bullet_types = { '-':0, '*':0, '+':0 }
  let g:vimwiki_number_types = ['1.']
  let g:vimwiki_list_markers = ['-', '*', '+', '1.']

  call s:init_mappings()
endfunction

" }}}1

function! s:init_mappings() " {{{1
  "
  " General wiki mappings
  "
  nnoremap <silent><buffer> <leader>wt :call vimwiki#page#create_toc()<cr>
  nnoremap <silent><buffer> <leader>wb :call vimwiki#get_backlinks()<cr>
  nnoremap <silent><buffer> <leader>wd :call vimwiki#page#delete()<cr>
  nnoremap <silent><buffer> <leader>wr :call vimwiki#page#rename()<cr>

  "
  " Link mappings
  "
  nnoremap <silent><buffer> <leader>wf :call vimwiki#link#toggle()<cr>

  "
  " Navigation
  "
  nnoremap <silent><buffer> <tab>      :call vimwiki#nav#next_link()<cr>
  nnoremap <silent><buffer> <s-tab>    :call vimwiki#nav#prev_link()<cr>
  nnoremap <silent><buffer> <bs>       :call vimwiki#nav#return()<cr>

  "
  " Open / toggle
  "
  nnoremap <silent><buffer> <cr>       :call vimwiki#link#open()<cr>
  nnoremap <silent><buffer> <c-cr>     :call vimwiki#link#open('vsplit')<cr>
  vnoremap <silent><buffer> <cr>       :<c-u>call vimwiki#link#toggle_visual()<cr>
  nnoremap <silent><buffer> gl         :set opfunc=vimwiki#link#toggle_operator<cr>g@

  "
  " Diary specific mappings
  "
  if b:vimwiki.in_diary
    nnoremap <silent><buffer> <c-j> :<c-u>call vimwiki#diary#go(-v:count1)<cr>
    nnoremap <silent><buffer> <c-k> :<c-u>call vimwiki#diary#go(v:count1)<cr>
    nnoremap <silent><buffer> <leader>wk :call vimwiki#diary#copy_note()<cr>
  endif
endfunction

" }}}1

"
" Miscellaneous
"
function! vimwiki#goto_index() " {{{1
  call vimwiki#url#parse('wiki:/index').open()
endfunction

" }}}1
" {{{1 function! vimwiki#reload()
let s:file = expand('<sfile>')
if get(s:, 'reload_guard', 1)
  function! vimwiki#reload()
    let s:reload_guard = 0

    " Reload autoload scripts
    for l:file in [s:file]
          \ + split(globpath(fnamemodify(s:file, ':r'), '*.vim'), '\n')
      execute 'source' l:file
    endfor

    " Reload plugin
    if exists('g:vimwiki_loaded')
      unlet g:vimwiki_loaded
      runtime plugin/vimwiki.vim
    endif

    " Reload ftplugin and syntax
    if &filetype == 'vimwiki'
      unlet b:did_ftplugin
      runtime ftplugin/vimwiki.vim

      if get(b:, 'current_syntax', '') ==# 'vimwiki'
        unlet b:current_syntax
        runtime syntax/vimwiki.vim
      endif
    endif

    unlet s:reload_guard
  endfunction
endif

" }}}1
function! vimwiki#get_backlinks() "{{{1
  let l:origin = expand('%:p')
  let l:locs = []

  for l:file in globpath(g:vimwiki.root, '**/*.wiki', 0, 1)
    if resolve(l:file) ==# resolve(l:origin) | break | endif

    for l:link in vimwiki#link#get_all(l:file)
      if get(l:link, 'scheme', '') !=# 'wiki' | continue | endif
      if resolve(l:link.path) ==# resolve(l:origin)
        call add(l:locs, {
              \ 'filename' : l:file,
              \ 'text' : empty(l:link.anchor) ? '' : 'Anchor: ' . l:link.anchor,
              \ 'lnum' : l:link.lnum,
              \ 'col' : l:link.c1
              \})
      endif
    endfor
  endfor

  if empty(l:locs)
    echomsg 'Vimwiki: No other file links to this file'
  else
    call setloclist(0, l:locs, 'r')
    lopen
  endif
endfunction

"}}}1

" vim: fdm=marker sw=2
