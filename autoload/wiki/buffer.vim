" A wiki plugin for Vim
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
  endif

  let b:wiki.in_journal = wiki#journal#is_in_journal(l:path, l:root)

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
  command! -buffer WikiGraphCheckOrphans  call wiki#graph#check_orphans()
  command! -buffer -count=1 WikiGraphIn   call wiki#graph#in(<count>)
  command! -buffer -count=1 WikiGraphOut  call wiki#graph#out(<count>)
  command! -buffer WikiJournalIndex       call wiki#journal#make_index()
  command! -buffer WikiLinkAdd            call g:wiki_select_method.links()
  command! -buffer WikiLinkRemove         call wiki#link#remove()
  command! -buffer WikiLinkNext           call wiki#nav#next_link()
  command! -buffer WikiLinkShow           call wiki#link#show()
  command! -buffer -range WikiLinkExtractHeader
        \ call wiki#link#set_text_from_header(<range>, <line1>, <line2>)
  command! -buffer WikiLinkFollow         call wiki#link#follow()
  command! -buffer WikiLinkFollowSplit    call wiki#link#follow(expand(<q-mods>) . ' split')
  command! -buffer WikiLinkFollowTab      call wiki#link#follow('tabedit')
  command! -buffer WikiLinkPrev           call wiki#nav#prev_link()
  command! -buffer WikiLinkReturn         call wiki#nav#return()
  command! -buffer WikiLinkTransform      call wiki#link#transform_current()
  command! -buffer WikiLinkIncomingToggle call wiki#link#incoming_display_toggle()
  command! -buffer WikiLinkIncomingHover  call wiki#link#incoming_hover()
  command! -buffer WikiPageDelete         call wiki#page#delete()
  command! -buffer WikiPageRename         call wiki#page#rename()
  command! -buffer WikiPageRenameSection  call wiki#page#rename_section()
  command! -buffer WikiToc                call g:wiki_select_method.toc()
  command! -buffer WikiTocGenerate        call wiki#toc#create(0)
  command! -buffer WikiTocGenerateLocal   call wiki#toc#create(1)
  command! -buffer -range=% -nargs=* WikiExport
        \ call wiki#page#export(<line1>, <line2>, <f-args>)

  command! -buffer          WikiTagReload call wiki#tags#reload()
  command! -buffer -nargs=* WikiTagList   call wiki#tags#list(<f-args>)
  command! -buffer -nargs=* WikiTagSearch call wiki#tags#search(<f-args>)
  command! -buffer -nargs=+ -complete=customlist,wiki#complete#tag_names
        \ WikiTagRename call wiki#tags#rename_ask(<f-args>)

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
  nnoremap <silent><buffer> <plug>(wiki-graph-check-orphans)  :WikiGraphCheckOrphans<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-in)             :WikiGraphIn<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-out)            :WikiGraphOut<cr>
  nnoremap <silent><buffer> <plug>(wiki-journal-index)        :WikiJournalIndex<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-add)             :WikiLinkAdd<cr>
  inoremap <silent><buffer> <plug>(wiki-link-add)             <cmd>call g:wiki_select_method.links('insert')<cr>
  xnoremap <silent><buffer> <plug>(wiki-link-add)             :call g:wiki_select_method.links('visual')<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-remove)          :WikiLinkRemove<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-next)            :WikiLinkNext<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-show)            :WikiLinkShow<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-extract-header)  :WikiLinkExtractHeader<cr>
  xnoremap <silent><buffer> <plug>(wiki-link-extract-header)  :WikiLinkExtractHeader<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-follow)          :WikiLinkFollow<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-follow-split)    :WikiLinkFollowSplit<cr>
  nnoremap         <buffer> <plug>(wiki-link-follow-vsplit)   :vert WikiLinkFollowSplit<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-follow-tab)      :WikiLinkFollowTab<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-prev)            :WikiLinkPrev<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-return)          :WikiLinkReturn<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-transform)       :WikiLinkTransform<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-incoming-toggle) :WikiLinkIncomingToggle<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-incoming-hover)  :WikiLinkIncomingHover<cr>
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

  xnoremap <silent><buffer> <plug>(wiki-link-transform-visual)   :<c-u>call wiki#link#transform_visual()<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-transform-operator) :set opfunc=wiki#link#transform_operator<cr>g@

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
          \ '<plug>(wiki-graph-find-backlinks)': '<wiki-prefix>gb',
          \ '<plug>(wiki-graph-related)': '<wiki-prefix>gr',
          \ '<plug>(wiki-graph-check-links)': '<wiki-prefix>gc',
          \ '<plug>(wiki-graph-check-links-g)': '<wiki-prefix>gC',
          \ '<plug>(wiki-graph-check-orphans)': '<wiki-prefix>gO',
          \ '<plug>(wiki-graph-in)': '<wiki-prefix>gi',
          \ '<plug>(wiki-graph-out)': '<wiki-prefix>go',
          \ '<plug>(wiki-link-add)': '<wiki-prefix>a',
          \ 'i_<plug>(wiki-link-add)': '<c-q>',
          \ 'x_<plug>(wiki-link-add)': '<wiki-prefix>a',
          \ '<plug>(wiki-link-remove)': '<wiki-prefix>lr',
          \ '<plug>(wiki-link-next)': '<tab>',
          \ '<plug>(wiki-link-prev)': '<s-tab>',
          \ '<plug>(wiki-link-show)': '<wiki-prefix>ll',
          \ '<plug>(wiki-link-extract-header)': '<wiki-prefix>lh',
          \ 'x_<plug>(wiki-link-extract-header)': '<wiki-prefix>lh',
          \ '<plug>(wiki-link-follow)': '<cr>',
          \ '<plug>(wiki-link-follow-split)': '<c-w><cr>',
          \ '<plug>(wiki-link-follow-vsplit)': '<c-w><tab>',
          \ '<plug>(wiki-link-follow-tab)': '<c-w>u',
          \ '<plug>(wiki-link-return)': '<bs>',
          \ '<plug>(wiki-link-transform)': '<wiki-prefix>f',
          \ '<plug>(wiki-link-transform-operator)': 'gl',
          \ '<plug>(wiki-link-incoming-toggle)': '<wiki-prefix>li',
          \ '<plug>(wiki-link-incoming-hover)': '<wiki-prefix>lI',
          \ '<plug>(wiki-page-delete)': '<wiki-prefix>d',
          \ '<plug>(wiki-page-rename)': '<wiki-prefix>r',
          \ '<plug>(wiki-page-rename-section)': '<f2>',
          \ '<plug>(wiki-toc-generate)': '<wiki-prefix>t',
          \ '<plug>(wiki-toc-generate-local)': '<wiki-prefix>T',
          \ '<plug>(wiki-export)': '<wiki-prefix>p',
          \ 'x_<plug>(wiki-export)': '<wiki-prefix>p',
          \ '<plug>(wiki-tag-list)': '<wiki-prefix>sl',
          \ '<plug>(wiki-tag-reload)': '<wiki-prefix>sr',
          \ '<plug>(wiki-tag-search)': '<wiki-prefix>ss',
          \ '<plug>(wiki-tag-rename)': '<wiki-prefix>sn',
          \ 'x_<plug>(wiki-link-transform-visual)': '<cr>',
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
            \ '<plug>(wiki-journal-toweek)': '<wiki-prefix>u',
            \ '<plug>(wiki-journal-tomonth)': '<wiki-prefix>m',
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
