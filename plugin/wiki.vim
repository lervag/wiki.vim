" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('g:wiki_loaded') | finish | endif
let g:wiki_loaded = 1

" Initialize options
call wiki#init#option('wiki_cache_persistent', 1)
call wiki#init#option('wiki_cache_root',
      \ wiki#u#is_win()
      \ ? fnamemodify(tempname(), ':h')
      \ : (empty($XDG_CACHE_HOME)
      \    ? $HOME . '/.cache'
      \    : $XDG_CACHE_HOME) . '/wiki.vim')
call wiki#init#option('wiki_completion_enabled', 1)
call wiki#init#option('wiki_completion_case_sensitive', 1)
call wiki#init#option('wiki_export', {
      \ 'args' : '',
      \ 'from_format' : 'markdown',
      \ 'ext' : 'pdf',
      \ 'link_ext_replace': v:false,
      \ 'view' : v:false,
      \ 'output' : fnamemodify(tempname(), ':h'),
      \})
call wiki#init#option('wiki_filetypes', ['md'])
call wiki#init#option('wiki_fzf_pages_opts', '')
call wiki#init#option('wiki_fzf_tags_opts', '')
call wiki#init#option('wiki_fzf_links_opts', '')
call wiki#init#option('wiki_global_load', 1)
call wiki#init#option('wiki_index_name', 'index')
call wiki#init#option('wiki_journal', {
      \ 'name' : 'journal',
      \ 'root' : '',
      \ 'frequency' : 'daily',
      \ 'date_format' : {
      \   'daily' : '%Y-%m-%d',
      \   'weekly' : '%Y_w%V',
      \   'monthly' : '%Y_m%m',
      \ },
      \})
call wiki#init#option('wiki_journal_index', {
      \ 'link_text_parser': { b, d, p -> d },
      \ 'link_url_parser': { b, d, p -> 'journal:' . d }
      \})
call wiki#init#option('wiki_link_creation', {
      \ 'md': {
      \   'link_type': 'md',
      \   'url_extension': '.md',
      \ },
      \ 'org': {
      \   'link_type': 'org',
      \   'url_extension': '.org',
      \ },
      \ 'adoc': {
      \   'link_type': 'adoc_xref_bracket',
      \   'url_extension': '',
      \ },
      \ '_': {
      \   'link_type': 'wiki',
      \   'url_extension': '',
      \ },
      \})
call wiki#init#option('wiki_link_default_schemes', {
      \ 'wiki': { 'wiki': 'wiki', 'adoc': 'adoc' },
      \ 'md': 'wiki',
      \ 'md_fig': 'file',
      \ 'org': 'wiki',
      \ 'adoc_xref_inline': 'adoc',
      \ 'adoc_xref_bracket': 'adoc',
      \ 'adoc_link': 'file',
      \ 'ref_target': '',
      \ 'date': 'journal',
      \ 'cite': 'zot',
      \})
call wiki#init#option('wiki_link_schemes', {})
call wiki#init#option('wiki_link_transform_on_follow', 1)
call wiki#init#option('wiki_link_transforms', {
      \ 'wiki': 'wiki#link#templates#md',
      \ 'md': 'wiki#link#templates#wiki',
      \ 'org': 'wiki#link#templates#org',
      \ 'adoc_xref_bracket': 'wiki#link#templates#adoc_xref_inline',
      \ 'adoc_xref_inline': 'wiki#link#templates#adoc_xref_bracket',
      \ 'date': 'wiki#link#templates#wiki',
      \ 'cite': 'wiki#link#templates#md',
      \ 'url': 'wiki#link#templates#md',
      \})
call wiki#init#option('wiki_mappings_use_defaults', 'all')
call wiki#init#option('wiki_mappings_prefix', '<leader>w')
call wiki#init#option('wiki_template_month_names', [
      \ 'January', 'February', 'March', 'April', 'May', 'June', 'July',
      \ 'August', 'September', 'October', 'November', 'December'
      \])
call wiki#init#option('wiki_root', '')
if has('nvim')
lua << EOF
  vim.fn["wiki#init#option"]("wiki_select_method", {
    pages = require("wiki.ui_select").pages,
    tags = require("wiki.ui_select").tags,
    toc = require("wiki.ui_select").toc,
    links = require("wiki.ui_select").links,
  })
EOF
else
  call wiki#init#option('wiki_select_method', {
        \ 'pages': function('wiki#fzf#pages'),
        \ 'tags': function('wiki#fzf#tags'),
        \ 'toc': function('wiki#fzf#toc'),
        \ 'links': function('wiki#fzf#links'),
        \})
endif
call wiki#init#option('wiki_tag_list', { 'output' : 'loclist' })
call wiki#init#option('wiki_tag_search', { 'output' : 'loclist' })
call wiki#init#option('wiki_tag_parsers', [g:wiki#tags#default_parser])
call wiki#init#option('wiki_tag_scan_num_lines', 15)
call wiki#init#option('wiki_templates', [])
call wiki#init#option('wiki_template_title_month',
      \ '# Summary, %(year) %(month-name)')
call wiki#init#option('wiki_template_title_week',
      \ '# Summary, %(year) week %(week)')
call wiki#init#option('wiki_toc_filetypes', {
      \ '_' : 'markdown',
      \ 'md' : 'markdown',
      \ 'adoc' : 'asciidoc',
      \ 'org' : 'org',
      \})
call wiki#init#option('wiki_toc_title', 'Contents')
call wiki#init#option('wiki_toc_depth', 6)
call wiki#init#option('wiki_ui_method', {
      \ 'confirm': has('nvim') ? 'nvim' : 'legacy',
      \ 'input': has('nvim') ? 'nvim' : 'legacy',
      \ 'select': has('nvim') ? 'nvim' : 'legacy',
      \})
call wiki#init#option('wiki_viewer', {
      \ '_' : get({
      \   'linux' : 'xdg-open',
      \   'mac' : 'open',
      \ }, wiki#u#get_os(), ''),
      \ 'md' : ':edit',
      \ 'wiki' : ':edit',
      \})
call wiki#init#option('wiki_write_on_nav', 1)
call wiki#init#option('wiki_zotero_root', '~/.local/zotero')

" Initialize global commands
command!          WikiEnable  call wiki#buffer#init()
command!          WikiIndex   call wiki#goto_index()
command! -nargs=? WikiOpen    call wiki#page#open(<f-args>)
command!          WikiReload  call wiki#reload()
command!          WikiJournal call wiki#journal#open()
command!          WikiPages   call g:wiki_select_method.pages()
command!          WikiTags    call g:wiki_select_method.tags()

" Initialize mappings
nnoremap <silent> <plug>(wiki-index)     :WikiIndex<cr>
nnoremap <silent> <plug>(wiki-open)      :WikiOpen<cr>
nnoremap <silent> <plug>(wiki-journal)   :WikiJournal<cr>
nnoremap <silent> <plug>(wiki-reload)    :WikiReload<cr>
nnoremap <silent> <plug>(wiki-pages)     :WikiPages<cr>
nnoremap <silent> <plug>(wiki-tags)      :WikiTags<cr>

" Apply default mappings
let s:mappings = index(['all', 'global'], g:wiki_mappings_use_defaults) >= 0
      \ ? {
      \ '<plug>(wiki-index)': '<wiki-prefix>w',
      \ '<plug>(wiki-open)': '<wiki-prefix>n',
      \ '<plug>(wiki-journal)': '<wiki-prefix><wiki-prefix>',
      \ '<plug>(wiki-reload)': '<wiki-prefix>x',
      \} : {}
call extend(s:mappings, get(g:, 'wiki_mappings_global', {}))
call wiki#init#apply_mappings_from_dict(s:mappings, '')

" Enable on desired filetypes
augroup wiki
  autocmd!
  for s:ft in g:wiki_filetypes
    execute 'autocmd BufRead,BufNewFile *.' . s:ft 'call s:autoload()'
  endfor
augroup END

function! s:autoload() abort
  if g:wiki_global_load
        \ || wiki#get_root_local() ==# wiki#get_root_global()
    WikiEnable
  endif
endfunction
