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

if g:vimwiki_conceallevel && exists("+conceallevel")
  let &l:conceallevel = g:vimwiki_conceallevel
endif

"Create 'formatlistpat'
let &formatlistpat = g:vimwiki_rxListItem

command! -buffer          VimwikiTOC            call vimwiki#base#table_of_contents(1)
command! -buffer -nargs=0 VimwikiBacklinks      call vimwiki#base#backlinks()
command! -buffer          VimwikiCheckLinks     call vimwiki#base#check_links()
command! -buffer -range   VimwikiToggleListItem call vimwiki#lst#toggle_cb(<line1>, <line2>)

"
" Keybindings
"
nnoremap <silent><buffer> <cr>       :call vimwiki#base#follow_link('nosplit')<cr>
nnoremap <silent><buffer> <tab>      :call vimwiki#base#find_next_link()<cr>
nnoremap <silent><buffer> <s-tab>    :call vimwiki#base#find_prev_link()<cr>
nnoremap <silent><buffer> <bs>       :call vimwiki#base#go_back_link()<cr>
nnoremap <silent><buffer> +          :call vimwiki#base#normalize_link(0)<cr>
nnoremap <silent><buffer> <c-cr>     :call vimwiki#base#follow_link('vsplit')<cr>
nnoremap <silent><buffer> <c-space>  :VimwikiToggleListItem<cr>
nnoremap <silent><buffer> <leader>wr :call vimwiki#base#rename_link()<cr>
nnoremap <silent><buffer> <leader>wd :call vimwiki#base#delete_link()<cr>
nnoremap <silent><buffer> <leader>wl :call vimwiki#backlinks()<cr>
nnoremap <silent><buffer> <leader>wf :call vimwiki#fix_syntax()<cr>

vnoremap <silent><buffer> <cr>      :<c-u>:call vimwiki#base#normalize_link(1)<cr>
vnoremap <silent><buffer> <c-space> :VimwikiToggleListItem<cr>


" Journal settings
if expand('%:p') =~# 'wiki\/journal'
  setlocal foldlevel=0
  nnoremap <silent><buffer> <leader>wk :call vimwiki#new_entry()<cr>
  nnoremap <silent><buffer> <c-j>      :call vimwiki#diary#goto_prev_day()<cr>
  nnoremap <silent><buffer> <c-k>      :call vimwiki#diary#goto_next_day()<cr>
else
  nnoremap <silent><buffer> <c-j>      :VimwikiMakeDiaryNote<cr>
  nnoremap <silent><buffer> <c-k>      :VimwikiMakeDiaryNote<cr>
endif

" {{{1 Link handler

function! VimwikiLinkHandler(link)
  let link_info = vimwiki#base#resolve_link(a:link)

  let lnk = expand(link_info.filename)
  if filereadable(lnk) && fnamemodify(lnk, ':e') ==? 'pdf'
    silent execute '!zathura ' lnk '&'
    return 1
  endif

  if link_info.scheme ==# 'file'
    let fname = link_info.filename
    if isdirectory(fname)
      execute 'Unite file:' . fname
      return 1
    elseif filereadable(fname)
      execute 'edit' fname
      return 1
    endif
  endif

  if link_info.scheme ==# 'doi'
    let url = substitute(link_info.filename, 'doi:', '', '')
    silent execute '!xdg-open http://dx.doi.org/' . url .'&'
    return 1
  endif

  return 0
endfunction

"}}}1

" vim: fdm=marker sw=2
