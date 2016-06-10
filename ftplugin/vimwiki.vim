" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

call vimwiki#define_regexes()

setlocal nolisp
setlocal nomodeline
setlocal nowrap
setlocal foldlevel=1
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
" setlocal formatoptions-=c
" setlocal formatoptions-=r
" setlocal formatoptions-=o
" setlocal formatoptions-=2
" setlocal formatoptions+=n

if exists("+conceallevel")
  let &l:conceallevel = 2
endif

"Create 'formatlistpat'
let &formatlistpat = g:vimwiki_rxListItem

command! -buffer          VimwikiTOC            call vimwiki#page#create_toc()
command! -buffer -nargs=0 VimwikiBacklinks      call vimwiki#page#backlinks()
command! -buffer -range   VimwikiToggleListItem call vimwiki#lst#toggle_cb(<line1>, <line2>)

"
" Keybindings
"
nnoremap <silent><buffer> <tab>      :call vimwiki#link#find_next()<cr>
nnoremap <silent><buffer> <s-tab>    :call vimwiki#link#find_prev()<cr>
nnoremap <silent><buffer> <bs>       :call vimwiki#link#go_back()<cr>

nnoremap <silent><buffer> <leader>wd :call vimwiki#page#delete()<cr>
nnoremap <silent><buffer> <leader>wr :call vimwiki#page#rename()<cr>

nnoremap <silent><buffer> <cr>       :call vimwiki#link#follow('nosplit')<cr>
nnoremap <silent><buffer> <c-cr>     :call vimwiki#link#follow('vsplit')<cr>

nnoremap <silent><buffer> <c-space>  :VimwikiToggleListItem<cr>

nnoremap <silent><buffer> <leader>wl :call vimwiki#backlinks()<cr>
nnoremap <silent><buffer> <leader>wf :call vimwiki#fix_syntax()<cr>

vnoremap <silent><buffer> <cr>      :<c-u>:call vimwiki#link#normalize(1)<cr>
vnoremap <silent><buffer> <c-space> :VimwikiToggleListItem<cr>


" Journal settings
if expand('%:p') =~# 'wiki\/journal'
  setlocal foldlevel=0
  nnoremap <silent><buffer> <leader>wk :call vimwiki#diary#copy_note()<cr>
  nnoremap <silent><buffer> <c-j>      :call vimwiki#diary#goto_prev_day()<cr>
  nnoremap <silent><buffer> <c-k>      :call vimwiki#diary#goto_next_day()<cr>
else
  nnoremap <silent><buffer> <c-j>      :call vimwiki#diary#make_note()<cr>
  nnoremap <silent><buffer> <c-k>      :call vimwiki#diary#make_note()<cr>

endif

" vim: fdm=marker sw=2
