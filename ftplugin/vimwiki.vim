if exists("b:did_ftplugin") | finish | endif
let b:did_ftplugin = 1

call vimwiki#u#reload_regexes()
call vimwiki#u#reload_omni_regexes()

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
setlocal comments=""
setlocal formatoptions-=c
setlocal formatoptions-=r
setlocal formatoptions-=o
setlocal formatoptions-=2
setlocal formatoptions+=n

if g:vimwiki_conceallevel && exists("+conceallevel")
  let &l:conceallevel = g:vimwiki_conceallevel
endif

"Create 'formatlistpat'
let &formatlistpat = g:vimwiki_rxListItem

command! -buffer          VimwikiTOC        call vimwiki#base#table_of_contents(1)
command! -buffer          VimwikiNextLink   call vimwiki#base#find_next_link()
command! -buffer          VimwikiPrevLink   call vimwiki#base#find_prev_link()
command! -buffer          VimwikiDeleteLink call vimwiki#base#delete_link()
command! -buffer          VimwikiRenameLink call vimwiki#base#rename_link()
command! -buffer          VimwikiFollowLink call vimwiki#base#follow_link('nosplit')
command! -buffer          VimwikiGoBackLink call vimwiki#base#go_back_link()
command! -buffer          VimwikiSplitLink  call vimwiki#base#follow_link('split')
command! -buffer          VimwikiVSplitLink call vimwiki#base#follow_link('vsplit')
command! -buffer -nargs=? VimwikiNormalizeLink call vimwiki#base#normalize_link(<f-args>)
command! -buffer          VimwikiTabnewLink call vimwiki#base#follow_link('tabnew')
command! -buffer          VimwikiGenerateLinks call vimwiki#base#generate_links()
command! -buffer -nargs=0 VimwikiBacklinks call vimwiki#base#backlinks()
command! -buffer VimwikiCheckLinks call vimwiki#base#check_links()

command! -buffer -nargs=+ VimwikiReturn call <SID>CR(<f-args>)
command! -buffer -range -nargs=1 VimwikiChangeSymbolTo call vimwiki#lst#change_marker(<line1>, <line2>, <f-args>, 'n')
command! -buffer -range -nargs=1 VimwikiListChangeSymbolI call vimwiki#lst#change_marker(<line1>, <line2>, <f-args>, 'i')
command! -buffer -nargs=1 VimwikiChangeSymbolInListTo call vimwiki#lst#change_marker_in_list(<f-args>)
command! -buffer -range VimwikiToggleListItem call vimwiki#lst#toggle_cb(<line1>, <line2>)
command! -buffer -range -nargs=+ VimwikiListChangeLvl call vimwiki#lst#change_level(<line1>, <line2>, <f-args>)
command! -buffer -range VimwikiRemoveSingleCB call vimwiki#lst#remove_cb(<line1>, <line2>)
command! -buffer VimwikiRemoveCBInList call vimwiki#lst#remove_cb_in_list()
command! -buffer VimwikiRenumberList call vimwiki#lst#adjust_numbered_list()
command! -buffer VimwikiRenumberAllLists call vimwiki#lst#adjust_whole_buffer()
command! -buffer VimwikiListToggle call vimwiki#lst#toggle_list_item()

command! -buffer VimwikiDiaryNextDay call vimwiki#diary#goto_next_day()
command! -buffer VimwikiDiaryPrevDay call vimwiki#diary#goto_prev_day()

command! VimwikiPrintWikiState call vimwiki#base#print_wiki_state()
command! VimwikiReadLocalOptions call vimwiki#base#read_wiki_options(1)

" KEYBINDINGS

nmap <silent><buffer> <CR> <Plug>VimwikiFollowLink
nnoremap <silent><script><buffer> <Plug>VimwikiFollowLink :VimwikiFollowLink<CR>

nmap <silent><buffer> <S-CR> <Plug>VimwikiSplitLink
nnoremap <silent><script><buffer> <Plug>VimwikiSplitLink :VimwikiSplitLink<CR>

nmap <silent><buffer> <C-CR> <Plug>VimwikiVSplitLink
nnoremap <silent><script><buffer> <Plug>VimwikiVSplitLink :VimwikiVSplitLink<CR>

nmap <silent><buffer> + <Plug>VimwikiNormalizeLink
nnoremap <silent><script><buffer> <Plug>VimwikiNormalizeLink :VimwikiNormalizeLink 0<CR>

vmap <silent><buffer> + <Plug>VimwikiNormalizeLinkVisual
vnoremap <silent><script><buffer> <Plug>VimwikiNormalizeLinkVisual :<C-U>VimwikiNormalizeLink 1<CR>

vmap <silent><buffer> <CR> <Plug>VimwikiNormalizeLinkVisualCR
vnoremap <silent><script><buffer> <Plug>VimwikiNormalizeLinkVisualCR :<C-U>VimwikiNormalizeLink 1<CR>

nmap <silent><buffer> <D-CR> <Plug>VimwikiTabnewLink
nmap <silent><buffer> <C-S-CR> <Plug>VimwikiTabnewLink
nnoremap <silent><script><buffer> <Plug>VimwikiTabnewLink :VimwikiTabnewLink<CR>

nmap <silent><buffer> <BS> <Plug>VimwikiGoBackLink
nnoremap <silent><script><buffer> <Plug>VimwikiGoBackLink :VimwikiGoBackLink<CR>

nmap <silent><buffer> <TAB> <Plug>VimwikiNextLink
nnoremap <silent><script><buffer> <Plug>VimwikiNextLink :VimwikiNextLink<CR>

nmap <silent><buffer> <S-TAB> <Plug>VimwikiPrevLink
nnoremap <silent><script><buffer> <Plug>VimwikiPrevLink :VimwikiPrevLink<CR>

exe 'nmap <silent><buffer> '.g:vimwiki_map_prefix.'d <Plug>VimwikiDeleteLink'
nnoremap <silent><script><buffer> <Plug>VimwikiDeleteLink :VimwikiDeleteLink<CR>

exe 'nmap <silent><buffer> '.g:vimwiki_map_prefix.'r <Plug>VimwikiRenameLink'
nnoremap <silent><script><buffer> <Plug>VimwikiRenameLink :VimwikiRenameLink<CR>

nmap <silent><buffer> <C-Down> <Plug>VimwikiDiaryNextDay
nnoremap <silent><script><buffer> <Plug>VimwikiDiaryNextDay :VimwikiDiaryNextDay<CR>

nmap <silent><buffer> <C-Up> <Plug>VimwikiDiaryPrevDay
nnoremap <silent><script><buffer> <Plug>VimwikiDiaryPrevDay :VimwikiDiaryPrevDay<CR>

" List mappings
nmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
vmap <silent><buffer> <C-Space> <Plug>VimwikiToggleListItem
nmap <silent><buffer> <C-@> <Plug>VimwikiToggleListItem
vmap <silent><buffer> <C-@> <Plug>VimwikiToggleListItem
nnoremap <silent><script><buffer> <Plug>VimwikiToggleListItem :VimwikiToggleListItem<CR>
vnoremap <silent><script><buffer> <Plug>VimwikiToggleListItem :VimwikiToggleListItem<CR>

imap <silent><buffer> <C-D> <Plug>VimwikiDecreaseLvlSingleItem
inoremap <silent><script><buffer> <Plug>VimwikiDecreaseLvlSingleItem <C-O>:VimwikiListChangeLvl decrease 0<CR>

imap <silent><buffer> <C-T> <Plug>VimwikiIncreaseLvlSingleItem
inoremap <silent><script><buffer> <Plug>VimwikiIncreaseLvlSingleItem <C-O>:VimwikiListChangeLvl increase 0<CR>

imap <silent><buffer> <C-L><C-J> <Plug>VimwikiListNextSymbol
inoremap <silent><script><buffer> <Plug>VimwikiListNextSymbol <C-O>:VimwikiListChangeSymbolI next<CR>

imap <silent><buffer> <C-L><C-K> <Plug>VimwikiListPrevSymbol
inoremap <silent><script><buffer> <Plug>VimwikiListPrevSymbol <C-O>:VimwikiListChangeSymbolI prev<CR>

imap <silent><buffer> <C-L><C-M> <Plug>VimwikiListToggle
inoremap <silent><script><buffer> <Plug>VimwikiListToggle <Esc>:VimwikiListToggle<CR>

nnoremap <silent> <buffer> o :call vimwiki#lst#kbd_o()<CR>
nnoremap <silent> <buffer> O :call vimwiki#lst#kbd_O()<CR>

nmap <silent><buffer> glr <Plug>VimwikiRenumberList
nnoremap <silent><script><buffer> <Plug>VimwikiRenumberList :VimwikiRenumberList<CR>

nmap <silent><buffer> gLr <Plug>VimwikiRenumberAllLists
nmap <silent><buffer> gLR <Plug>VimwikiRenumberAllLists
nnoremap <silent><script><buffer>
       <Plug>VimwikiRenumberAllLists :VimwikiRenumberAllLists<CR>

map <silent><buffer> glh <Plug>VimwikiDecreaseLvlSingleItem
noremap <silent><script><buffer> <Plug>VimwikiDecreaseLvlSingleItem :VimwikiListChangeLvl decrease 0<CR>

map <silent><buffer> gll <Plug>VimwikiIncreaseLvlSingleItem
noremap <silent><script><buffer> <Plug>VimwikiIncreaseLvlSingleItem :VimwikiListChangeLvl increase 0<CR>

map <silent><buffer> gLh <Plug>VimwikiDecreaseLvlWholeItem
map <silent><buffer> gLH <Plug>VimwikiDecreaseLvlWholeItem
noremap <silent><script><buffer> <Plug>VimwikiDecreaseLvlWholeItem :VimwikiListChangeLvl decrease 1<CR>

map <silent><buffer> gLl <Plug>VimwikiIncreaseLvlWholeItem
map <silent><buffer> gLL <Plug>VimwikiIncreaseLvlWholeItem
noremap <silent><script><buffer> <Plug>VimwikiIncreaseLvlWholeItem :VimwikiListChangeLvl increase 1<CR>

map <silent><buffer> gl<Space> <Plug>VimwikiRemoveSingleCB
noremap <silent><script><buffer> <Plug>VimwikiRemoveSingleCB :VimwikiRemoveSingleCB<CR>

map <silent><buffer> gL<Space> <Plug>VimwikiRemoveCBInList
noremap <silent><script><buffer> <Plug>VimwikiRemoveCBInList :VimwikiRemoveCBInList<CR>

function! s:CR(normal, just_mrkr) "{{{
  if g:vimwiki_table_mappings
    let res = vimwiki#tbl#kbd_cr()
    if res != ""
      exe "normal! " . res . "\<Right>"
      startinsert
      return
    endif
  endif
  call vimwiki#lst#kbd_cr(a:normal, a:just_mrkr)
endfunction "}}}

if maparg('<CR>', 'i') !~? '<Esc>:VimwikiReturn'
  inoremap <silent><buffer> <CR> <Esc>:VimwikiReturn 1 5<CR>
endif
if maparg('<S-CR>', 'i') !~? '<Esc>:VimwikiReturn'
  inoremap <silent><buffer> <S-CR> <Esc>:VimwikiReturn 2 2<CR>
endif

nnoremap <buffer> gqq :VimwikiTableAlignQ<CR>
nnoremap <buffer> gww :VimwikiTableAlignW<CR>
if !hasmapto('<Plug>VimwikiTableMoveColumnLeft')
  nmap <silent><buffer> <A-Left> <Plug>VimwikiTableMoveColumnLeft
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiTableMoveColumnLeft :VimwikiTableMoveColumnLeft<CR>
if !hasmapto('<Plug>VimwikiTableMoveColumnRight')
  nmap <silent><buffer> <A-Right> <Plug>VimwikiTableMoveColumnRight
endif
nnoremap <silent><script><buffer>
      \ <Plug>VimwikiTableMoveColumnRight :VimwikiTableMoveColumnRight<CR>

onoremap <silent><buffer> ah :<C-U>call vimwiki#base#TO_header(0, 0)<CR>
vnoremap <silent><buffer> ah :<C-U>call vimwiki#base#TO_header(0, 1)<CR>
onoremap <silent><buffer> ih :<C-U>call vimwiki#base#TO_header(1, 0)<CR>
vnoremap <silent><buffer> ih :<C-U>call vimwiki#base#TO_header(1, 1)<CR>
onoremap <silent><buffer> al :<C-U>call vimwiki#lst#TO_list_item(0, 0)<CR>
vnoremap <silent><buffer> al :<C-U>call vimwiki#lst#TO_list_item(0, 1)<CR>
onoremap <silent><buffer> il :<C-U>call vimwiki#lst#TO_list_item(1, 0)<CR>
vnoremap <silent><buffer> il :<C-U>call vimwiki#lst#TO_list_item(1, 1)<CR>

" Define mappings
nnoremap <silent><buffer> <leader>wl :call vimwiki#backlinks()<cr>
nnoremap <silent><buffer> <leader>wf :call vimwiki#fix_syntax()<cr>
nnoremap <silent><buffer> <leader>wx :call vimwiki#reload_personal_script()<cr>

" Journal settings
if expand('%:p') =~# 'wiki\/journal'
  setlocal foldlevel=0
  nnoremap <silent><buffer> <leader>wk :call vimwiki#new_entry()<cr>
  nnoremap <silent><buffer> <c-k>      :VimwikiDiaryNextDay<cr>
  nnoremap <silent><buffer> <c-j>      :VimwikiDiaryPrevDay<cr>
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
