" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#buffer#init() abort " {{{1
  setlocal comments+=nb:>

  if g:wiki_completion_enabled
    setlocal omnifunc=wiki#complete#omnicomplete
  endif

  let b:wiki = {}
  let b:wiki.extension = expand('%:e')
  let b:wiki.index_name = g:wiki_index_name

  let l:root = wiki#get_root()
  let l:file = resolve(expand('%:p'))
  let l:path = expand('%:p:h')

  " Only set b:wiki.root if current file is inside wiki#get_root result
  if stridx(l:path, l:root) == 0
    let b:wiki.root = l:root
    let b:wiki.root_journal = wiki#paths#s(
          \ printf('%s/%s', l:root, g:wiki_journal.name))
    let b:wiki.in_journal = stridx(l:file, b:wiki.root_journal) == 0
  else
    let b:wiki.in_journal = v:false
  endif

  call s:init_buffer_commands()
  call s:init_buffer_mappings()

  call wiki#template#init()

  if exists('#User#WikiBufferInitialized')
    doautocmd <nomodeline> User WikiBufferInitialized
  endif
endfunction

" }}}1


function! s:init_buffer_commands() abort " {{{1
  command! -buffer WikiGraphFindBacklinks call wiki#graph#find_backlinks()
  command! -buffer WikiGraphRelated       call wiki#graph#show_related()
  command! -buffer WikiGraphCheckLinks    call wiki#graph#check_links(expand('%:p'))
  command! -buffer WikiGraphCheckLinksG   call wiki#graph#check_links()
  command! -buffer -count=99 WikiGraphIn  call wiki#graph#in(<count>)
  command! -buffer -count=99 WikiGraphOut call wiki#graph#out(<count>)
  command! -buffer WikiJournalIndex       call wiki#journal#make_index()
  command! -buffer WikiLinkNext           call wiki#nav#next_link()
  command! -buffer WikiLinkShow           call wiki#link#show()
  command! -buffer WikiLinkExtractHeader  call wiki#link#set_text_from_header()
  command! -buffer WikiLinkFollow         call wiki#link#follow()
  command! -buffer WikiLinkFollowSplit    call wiki#link#follow('split', <q-mods>)
  command! -buffer WikiLinkFollowTab      call wiki#link#follow('tabe')
  command! -buffer WikiLinkPrev           call wiki#nav#prev_link()
  command! -buffer WikiLinkReturn         call wiki#nav#return()
  command! -buffer WikiLinkToggle         call wiki#link#toggle_current()
  command! -buffer WikiPageDelete         call wiki#page#delete()
  command! -buffer WikiPageRename         call wiki#page#rename()
  command! -buffer WikiPageRenameSection  call wiki#page#rename_section()
  command! -buffer WikiTocGenerate        call wiki#toc#create(0)
  command! -buffer WikiTocGenerateLocal   call wiki#toc#create(1)
  command! -buffer -range=% -nargs=* WikiExport
        \ call wiki#page#export(<line1>, <line2>, <f-args>)

  command! -buffer          WikiTagReload call wiki#tags#reload()
  command! -buffer -nargs=* WikiTagList   call wiki#tags#list(<f-args>)
  command! -buffer -nargs=* WikiTagSearch call wiki#tags#search(<f-args>)
  command! -buffer -nargs=+ -complete=custom,wiki#tags#get_tag_names
        \ WikiTagRename call wiki#tags#rename_ask(<f-args>)

  if has('nvim') && g:wiki_select_method == 'ui_select'
    command! -buffer WikiToc lua require('wiki').toc()
  else
    command! -buffer WikiToc call wiki#fzf#toc()
  endif
  command! -buffer -nargs=1 WikiClearCache call wiki#cache#clear(<q-args>)

  if b:wiki.in_journal
    command! -buffer -count=1 WikiJournalPrev       call wiki#journal#go(-<count>)
    command! -buffer -count=1 WikiJournalNext       call wiki#journal#go(<count>)
    command! -buffer          WikiJournalCopyToNext call wiki#journal#copy_to_next()
    command! -buffer          WikiJournalToWeek     call wiki#journal#go_to_frq('weekly')
    command! -buffer          WikiJournalToMonth    call wiki#journal#go_to_frq('monthly')
  endif
endfunction

" }}}1
function! s:init_buffer_mappings() abort " {{{1
  nnoremap <silent><buffer> <plug>(wiki-graph-find-backlinks) :WikiGraphFindBacklinks<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-related)        :WikiGraphRelated<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-check-links)    :WikiGraphCheckLinks<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-check-links-g)  :WikiGraphCheckLinksG<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-in)             :WikiGraphIn<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-out)            :WikiGraphOut<cr>
  nnoremap <silent><buffer> <plug>(wiki-journal-index)        :WikiJournalIndex<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-next)            :WikiLinkNext<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-show)            :WikiLinkShow<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-extract-header)  :WikiLinkExtractHeader<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-follow)          :WikiLinkFollow<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-follow-split)    :WikiLinkFollowSplit<cr>
  nnoremap         <buffer> <plug>(wiki-link-follow-vsplit)   :vert WikiLinkFollowSplit<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-follow-tab)      :WikiLinkFollowTab<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-prev)            :WikiLinkPrev<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-return)          :WikiLinkReturn<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-toggle)          :WikiLinkToggle<cr>
  nnoremap <silent><buffer> <plug>(wiki-page-delete)          :WikiPageDelete<cr>
  nnoremap <silent><buffer> <plug>(wiki-page-rename)          :WikiPageRename<cr>
  nnoremap <silent><buffer> <plug>(wiki-page-rename-section)  :WikiPageRenameSection<cr>
  nnoremap <silent><buffer> <plug>(wiki-toc-generate)         :WikiTocGenerate<cr>
  nnoremap <silent><buffer> <plug>(wiki-toc-generate-local)   :WikiTocGenerateLocal<cr>
  nnoremap <silent><buffer> <plug>(wiki-export)               :WikiExport<cr>
  xnoremap <silent><buffer> <plug>(wiki-export)               :WikiExport<cr>
  nnoremap <silent><buffer> <plug>(wiki-tag-list)             :WikiTagList<cr>
  nnoremap <silent><buffer> <plug>(wiki-tag-reload)           :WikiTagReload<cr>
  nnoremap <silent><buffer> <plug>(wiki-tag-search)           :WikiTagSearch<cr>
  nnoremap <silent><buffer> <plug>(wiki-tag-rename)           :WikiTagRename<cr>

  nnoremap <silent><buffer> <plug>(wiki-toc)                  :WikiToc<cr>
  inoremap <silent><buffer> <plug>(wiki-toc)                  <esc>:WikiToc<cr>

  xnoremap <silent><buffer> <plug>(wiki-link-toggle-visual)   :<c-u>call wiki#link#toggle_visual()<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-toggle-operator) :set opfunc=wiki#link#toggle_operator<cr>g@

  onoremap <silent><buffer> <plug>(wiki-au) :call wiki#text_obj#link(0, 0)<cr>
  xnoremap <silent><buffer> <plug>(wiki-au) :<c-u>call wiki#text_obj#link(0, 1)<cr>
  onoremap <silent><buffer> <plug>(wiki-iu) :call wiki#text_obj#link(1, 0)<cr>
  xnoremap <silent><buffer> <plug>(wiki-iu) :<c-u>call wiki#text_obj#link(1, 1)<cr>
  onoremap <silent><buffer> <plug>(wiki-at) :call wiki#text_obj#link_text(0, 0)<cr>
  xnoremap <silent><buffer> <plug>(wiki-at) :<c-u>call wiki#text_obj#link_text(0, 1)<cr>
  onoremap <silent><buffer> <plug>(wiki-it) :call wiki#text_obj#link_text(1, 0)<cr>
  xnoremap <silent><buffer> <plug>(wiki-it) :<c-u>call wiki#text_obj#link_text(1, 1)<cr>

  if b:wiki.in_journal
    nnoremap <silent><buffer> <plug>(wiki-journal-prev)        :WikiJournalPrev<cr>
    nnoremap <silent><buffer> <plug>(wiki-journal-next)        :WikiJournalNext<cr>
    nnoremap <silent><buffer> <plug>(wiki-journal-copy-tonext) :WikiJournalCopyToNext<cr>
    nnoremap <silent><buffer> <plug>(wiki-journal-toweek)      :WikiJournalToWeek<cr>
    nnoremap <silent><buffer> <plug>(wiki-journal-tomonth)     :WikiJournalToMonth<cr>
  endif


  let l:mappings = {}
  if index(['all', 'local'], g:wiki_mappings_use_defaults) >= 0
    let l:mappings = {
          \ '<plug>(wiki-graph-find-backlinks)': '<leader>wgb',
          \ '<plug>(wiki-graph-related)': '<leader>wgr',
          \ '<plug>(wiki-graph-check-links)': '<leader>wgc',
          \ '<plug>(wiki-graph-check-links-g)': '<leader>wgC',
          \ '<plug>(wiki-graph-in)': '<leader>wgi',
          \ '<plug>(wiki-graph-out)': '<leader>wgo',
          \ '<plug>(wiki-link-next)': '<tab>',
          \ '<plug>(wiki-link-prev)': '<s-tab>',
          \ '<plug>(wiki-link-show)': '<leader>wll',
          \ '<plug>(wiki-link-extract-header)': '<leader>wlh',
          \ '<plug>(wiki-link-follow)': '<cr>',
          \ '<plug>(wiki-link-follow-split)': '<c-w><cr>',
          \ '<plug>(wiki-link-follow-vsplit)': '<c-w><tab>',
          \ '<plug>(wiki-link-follow-tab)': '<c-w>u',
          \ '<plug>(wiki-link-return)': '<bs>',
          \ '<plug>(wiki-link-toggle)': '<leader>wf',
          \ '<plug>(wiki-link-toggle-operator)': 'gl',
          \ '<plug>(wiki-page-delete)': '<leader>wd',
          \ '<plug>(wiki-page-rename)': '<leader>wr',
          \ '<plug>(wiki-page-rename-section)': '<f2>',
          \ '<plug>(wiki-toc-generate)': '<leader>wt',
          \ '<plug>(wiki-toc-generate-local)': '<leader>wT',
          \ '<plug>(wiki-export)': '<leader>wp',
          \ 'x_<plug>(wiki-export)': '<leader>wp',
          \ '<plug>(wiki-tag-list)': '<leader>wsl',
          \ '<plug>(wiki-tag-reload)': '<leader>wsr',
          \ '<plug>(wiki-tag-search)': '<leader>wss',
          \ '<plug>(wiki-tag-rename)': '<leader>wsn',
          \ 'x_<plug>(wiki-link-toggle-visual)': '<cr>',
          \ 'o_<plug>(wiki-au)': 'au',
          \ 'x_<plug>(wiki-au)': 'au',
          \ 'o_<plug>(wiki-iu)': 'iu',
          \ 'x_<plug>(wiki-iu)': 'iu',
          \ 'o_<plug>(wiki-at)': 'at',
          \ 'x_<plug>(wiki-at)': 'at',
          \ 'o_<plug>(wiki-it)': 'it',
          \ 'x_<plug>(wiki-it)': 'it',
          \}

    if b:wiki.in_journal
      call extend(l:mappings, {
            \ '<plug>(wiki-journal-prev)': '<c-p>',
            \ '<plug>(wiki-journal-next)': '<c-n>',
            \ '<plug>(wiki-journal-copy-tonext)': '<leader><c-n>',
            \ '<plug>(wiki-journal-toweek)': '<leader>wu',
            \ '<plug>(wiki-journal-tomonth)': '<leader>wm',
            \})
    endif
  endif

  call extend(l:mappings, get(g:, 'wiki_mappings_local', {}))
  if b:wiki.in_journal
    call extend(l:mappings, get(g:, 'wiki_mappings_local_journal', {}))
  endif

  call wiki#init#apply_mappings_from_dict(l:mappings, '<buffer>')
endfunction

" }}}1
