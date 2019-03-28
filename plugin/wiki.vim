" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

if exists('g:wiki_loaded') | finish | endif
let g:wiki_loaded = 1

" Initialize option
let g:wiki_journal = get(g:, 'wiki_journal', 'journal')
let g:wiki_viewer = extend({
      \ '_' : get({
      \   'linux' : 'xdg-open',
      \   'mac'   : 'open',
      \ }, wiki#init#get_os(), ''),
      \}, get(g:, 'wiki_viewer', {}))
let g:wiki_export = extend({
      \ 'args' : '',
      \ 'from_format' : 'gfm',
      \ 'ext' : 'pdf',
      \ 'view' : v:false,
      \}, get(g:, 'wiki_export', {}))
let g:wiki_filetypes = get(g:, 'wiki_filetypes', ['wiki'])
let g:wiki_index_name = get(g:, 'wiki_index_name', 'index')
let g:wiki_root = get(g:, 'wiki_root', '')
let g:wiki_link_extension = get(g:, 'wiki_link_extension', '')
let g:wiki_link_target_map = get(g:, 'wiki_link_target_map', '')
let g:wiki_month_names = get(g:, 'wiki_month_names', [
      \ 'January',
      \ 'February',
      \ 'March',
      \ 'April',
      \ 'May',
      \ 'June',
      \ 'July',
      \ 'August',
      \ 'September',
      \ 'October',
      \ 'November',
      \ 'December'
      \])
let g:wiki_template_title_week = get(g:, 'wiki_template_title_week',
      \ '# Summary, %(year) week %(week)')
let g:wiki_template_title_month = get(g:, 'wiki_template_title_month',
      \ '# Summary, %(year) %(month-name)')

" Initialize global commands
command! WikiEnable  call wiki#buffer#init()
command! WikiIndex   call wiki#goto_index()
command! WikiReload  call wiki#reload()
command! WikiJournal call wiki#journal#make_note()
command! CtrlPWiki   call ctrlp#init(ctrlp#wiki#id())

" Initialize mappings
nnoremap <silent> <plug>(wiki-index)   :WikiIndex<cr>
nnoremap <silent> <plug>(wiki-journal) :WikiJournal<cr>
nnoremap <silent> <plug>(wiki-reload)  :WikiReload<cr>

" Apply default mappings
let s:mappings = get(g:, 'wiki_mappings_use_defaults', 1)
      \ ? {
      \ '<plug>(wiki-index)' : '<leader>ww',
      \ '<plug>(wiki-journal)' : '<leader>w<leader>w',
      \ '<plug>(wiki-reload)' : '<leader>wx',
      \} : {}
call extend(s:mappings, get(g:, 'wiki_mappings_global', {}))
call wiki#init#apply_mappings_from_dict(s:mappings, '')

" Enable on desired filetypes
augroup wiki
  autocmd!
  for s:ft in g:wiki_filetypes
    execute 'autocmd BufRead,BufNewFile *.' . s:ft 'WikiEnable'
  endfor
augroup END
