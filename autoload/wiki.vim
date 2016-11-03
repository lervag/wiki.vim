" wiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" Init functions
"
function! wiki#init() " {{{1
  "
  " Require minimum configuration
  "
  if !exists('g:wiki') || !exists('g:wiki.root')
    echomsg 'Please define g:wiki.root!'
    return
  endif

  "
  " Only load the plugin once
  "
  if get(g:wiki, 'loaded', 0) | return | endif
  let g:wiki.loaded = 1

  "
  " Ensure absolute path
  "
  let g:wiki.root = fnamemodify(g:wiki.root, ':p')
  let g:wiki.journal = g:wiki.root . 'journal/'

  "
  " Warn if wiki path is invalid
  "
  if !isdirectory(g:wiki.root)
    return
  endif

  "
  " Define mappings
  "
  nnoremap <silent> <leader>ww         :call wiki#goto_index()<cr>
  nnoremap <silent> <leader>wx         :call wiki#reload()<cr>
  nnoremap <silent> <leader>w<leader>w :call wiki#journal#make_note()<cr>
endfunction

" }}}1
function! wiki#init_buffer() " {{{1
  setlocal nolisp
  setlocal nomodeline
  setlocal nowrap
  setlocal foldmethod=expr
  setlocal foldexpr=wiki#fold#level(v:lnum)
  setlocal foldtext=wiki#fold#text()
  setlocal omnifunc=wiki#complete#omnicomplete
  setlocal suffixesadd=.wiki
  setlocal isfname-=[,]
  setlocal autoindent
  setlocal nosmartindent
  setlocal nocindent
  setlocal comments =f:*\ TODO:,fb:*\ [\ ],fb:*\ [X],fb:*
  setlocal comments+=f:-\ TODO:,fb:-\ [\ ],fb:-\ [X],fb:-
  setlocal comments+=nb:>
  let &l:commentstring = '// %s'
  setlocal formatoptions-=o
  setlocal formatoptions+=n
  let &l:formatlistpat = '\v^\s*%(\d|\l|i+)\.\s'

  augroup wiki
    autocmd!
    autocmd BufWinEnter *.wiki setlocal conceallevel=2
  augroup END

  let b:wiki = {
        \ 'in_journal' : stridx(
        \   resolve(expand('%:p')),
        \   resolve(g:wiki.journal)) == 0
        \ }

  " TODO
  let g:wiki_bullet_types = { '-':0, '*':0, '+':0 }
  let g:wiki_number_types = ['1.']
  let g:wiki_list_markers = ['-', '*', '+', '1.']

  call s:init_mappings()
  call s:init_prefill()
endfunction

" }}}1

function! s:init_mappings() " {{{1
  "
  " Journal specific mappings
  "
  if b:wiki.in_journal
    nnoremap <silent><buffer> <c-j> :<c-u>call wiki#journal#go(-v:count1)<cr>
    nnoremap <silent><buffer> <c-k> :<c-u>call wiki#journal#go(v:count1)<cr>
    nnoremap <silent><buffer> <leader>wk :call wiki#journal#copy_note()<cr>
    nnoremap <silent><buffer> <leader>wu :call wiki#journal#go_to_week()<cr>
    nnoremap <silent><buffer> <leader>wm :call wiki#journal#go_to_month()<cr>
  endif

  "
  " General wiki mappings
  "
  nnoremap <silent><buffer> <leader>wt :call wiki#page#create_toc()<cr>
  nnoremap <silent><buffer> <leader>wb :call wiki#get_backlinks()<cr>
  nnoremap <silent><buffer> <leader>wd :call wiki#page#delete()<cr>
  nnoremap <silent><buffer> <leader>wr :call wiki#page#rename()<cr>
  nnoremap <silent><buffer> <leader>wh :call wiki#timesheet#show()<cr>
  nnoremap <silent><buffer> <leader>wf :call wiki#link#toggle()<cr>
  nnoremap <silent><buffer> <leader>wc :call wiki#u#run_code_snippet()<cr>

  "
  " Navigation
  "
  nnoremap <silent><buffer> <tab>      :call wiki#nav#next_link()<cr>
  nnoremap <silent><buffer> <s-tab>    :call wiki#nav#prev_link()<cr>
  nnoremap <silent><buffer> <bs>       :call wiki#nav#return()<cr>

  "
  " Open / toggle
  "
  nnoremap <silent><buffer> <cr>       :call wiki#link#open()<cr>
  nnoremap <silent><buffer> <c-cr>     :call wiki#link#open('vsplit')<cr>
  vnoremap <silent><buffer> <cr>       :<c-u>call wiki#link#toggle_visual()<cr>
  nnoremap <silent><buffer> gl         :set opfunc=wiki#link#toggle_operator<cr>g@

  "
  " Lists
  "
  nnoremap <silent><buffer>       <c-space> :call wiki#list#toggle_todo()<cr>
  inoremap <silent><buffer><expr> <c-cr>    wiki#list#new_line_bullet()

  "
  " Text objects
  "
  onoremap <silent><buffer> al :call wiki#text_obj#link(0)<cr>
  xnoremap <silent><buffer> al :call wiki#text_obj#link(0)<cr>
  onoremap <silent><buffer> il :call wiki#text_obj#link(1)<cr>
  xnoremap <silent><buffer> il :call wiki#text_obj#link(1)<cr>
  onoremap <silent><buffer> at :call wiki#text_obj#link_text(0)<cr>
  xnoremap <silent><buffer> at :call wiki#text_obj#link_text(0)<cr>
  onoremap <silent><buffer> it :call wiki#text_obj#link_text(1)<cr>
  xnoremap <silent><buffer> it :call wiki#text_obj#link_text(1)<cr>
  onoremap <silent><buffer> ac :call wiki#text_obj#code(0)<cr>
  xnoremap <silent><buffer> ac :call wiki#text_obj#code(0)<cr>
  onoremap <silent><buffer> ic :call wiki#text_obj#code(1)<cr>
  xnoremap <silent><buffer> ic :call wiki#text_obj#code(1)<cr>
endfunction

" }}}1
function! s:init_prefill() " {{{1
  if filereadable(expand('%')) | return | endif

  let l:match = matchlist(expand('%:t:r'), '^\(\d\d\d\d\)_\(\w\)\(\d\d\)$')
  if empty(l:match) | return | endif
  let [l:year, l:type, l:number] = l:match[1:3]

  if l:type ==# 'w'
    call wiki#template#weekly_summary(l:year, l:number)
  elseif l:type ==# 'm'
    call wiki#template#monthly_summary(l:year, l:number)
  endif
endfunction

" }}}1

"
" Miscellaneous
"
function! wiki#goto_index() " {{{1
  call wiki#url#parse('wiki:/index').open()
endfunction

" }}}1
" {{{1 function! wiki#reload()
let s:file = expand('<sfile>')
if get(s:, 'reload_guard', 1)
  function! wiki#reload()
    let s:reload_guard = 0
    let l:foldmethod = &l:foldmethod

    " Reload autoload scripts
    for l:file in [s:file]
          \ + split(globpath(fnamemodify(s:file, ':r'), '*.vim'), '\n')
      execute 'source' l:file
    endfor

    " Reload plugin
    if exists('g:wiki_loaded')
      unlet g:wiki_loaded
      runtime plugin/wiki.vim
    endif

    " Reload ftplugin and syntax
    if &filetype == 'wiki'
      unlet b:did_ftplugin
      runtime ftplugin/wiki.vim

      if get(b:, 'current_syntax', '') ==# 'wiki'
        unlet b:current_syntax
        runtime syntax/wiki.vim
      endif
    endif

    let &l:foldmethod = l:foldmethod
    unlet s:reload_guard
  endfunction
endif

" }}}1
function! wiki#get_backlinks() "{{{1
  let l:origin = expand('%:p')
  let l:locs = []

  for l:file in globpath(g:wiki.root, '**/*.wiki', 0, 1)
    if resolve(l:file) ==# resolve(l:origin) | continue | endif
    echon "\rwiki: Scanning " . fnamemodify(l:file, ':t')

    for l:link in wiki#link#get_all(l:file)
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
  echon "\rwiki: Scanning completed" . repeat(' ', 40)

  if empty(l:locs)
    echomsg 'wiki: No other file links to this file'
  else
    call setloclist(0, l:locs, 'r')
    lopen
  endif
endfunction

"}}}1

" vim: fdm=marker sw=2
