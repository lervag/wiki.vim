" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#buffer#init() abort " {{{1
  " Convenience: Set completion function
  setlocal omnifunc=wiki#complete#omnicomplete

  " Convenience: Set 'comments' option for list
  setlocal comments+=fb:*,f:*\ TODO:,b:*\ [\ ],b:*\ [x]
  setlocal comments+=fb:-,f:-\ TODO:,b:-\ [\ ],b:-\ [x]
  setlocal comments+=nb:>

  " Initialize the b:wiki state
  let b:wiki = {}
  let b:wiki.root = wiki#get_root()
  let b:wiki.root_journal = printf('%s/%s', b:wiki.root, g:wiki_journal.name)
  let b:wiki.extension = expand('%:e')
  let b:wiki.index_name = g:wiki_index_name
  let b:wiki.link_extension = g:wiki_link_extension
  let b:wiki.in_journal = stridx(resolve(expand('%:p')),
        \ b:wiki.root_journal) == 0

  call s:init_buffer_commands()
  call s:init_buffer_mappings()

  call s:apply_template()

  if exists('#User#WikiBufferInitialized')
    doautocmd <nomodeline> User WikiBufferInitialized
  endif
endfunction

" }}}1


function! s:init_buffer_commands() abort " {{{1
  command! -buffer WikiCodeRun            call wiki#u#run_code_snippet()
  command! -buffer WikiGraphFindBacklinks call wiki#graph#find_backlinks()
  command! -buffer -count=99 WikiGraphIn  call wiki#graph#in(<count>)
  command! -buffer -count=99 WikiGraphOut call wiki#graph#out(<count>)
  command! -buffer WikiJournalIndex       call wiki#journal#make_index()
  command! -buffer WikiLinkNext           call wiki#nav#next_link()
  command! -buffer WikiLinkShow           call wiki#link#show()
  command! -buffer WikiLinkOpen           call wiki#link#open()
  command! -buffer WikiLinkOpenSplit      call wiki#link#open('vsplit')
  command! -buffer WikiLinkPrev           call wiki#nav#prev_link()
  command! -buffer WikiLinkReturn         call wiki#nav#return()
  command! -buffer WikiLinkToggle         call wiki#link#toggle()
  command! -buffer WikiListMoveUp         call wiki#list#move(0)
  command! -buffer WikiListMoveDown       call wiki#list#move(1)
  command! -buffer WikiListToggle         call wiki#list#toggle()
  command! -buffer WikiListUniq           call wiki#list#uniq(0)
  command! -buffer WikiListUniqLocal      call wiki#list#uniq(1)
  command! -buffer WikiListShowItem       call wiki#list#show_item()
  command! -buffer WikiPageDelete         call wiki#page#delete()
  command! -buffer WikiPageRename         call wiki#page#rename_ask()
  command! -buffer WikiPageToc            call wiki#page#create_toc(0)
  command! -buffer WikiPageTocLocal       call wiki#page#create_toc(1)
  command! -buffer -range=% -nargs=* WikiExport
        \ call wiki#page#export(<line1>, <line2>, <f-args>)

  command! -buffer          WikiTagList   call wiki#tags#list()
  command! -buffer          WikiTagReload call wiki#tags#reload()
  command! -buffer -nargs=* WikiTagSearch call wiki#tags#search(<f-args>)

  command! -buffer          WikiFzfToc    call wiki#fzf#toc()

  if b:wiki.in_journal
    command! -buffer -count=1 WikiJournalPrev       call wiki#journal#go(-<count>)
    command! -buffer -count=1 WikiJournalNext       call wiki#journal#go(<count>)
    command! -buffer          WikiJournalCopyToNext call wiki#journal#copy_note()
    command! -buffer          WikiJournalToWeek     call wiki#journal#freq('weekly')
    command! -buffer          WikiJournalToMonth    call wiki#journal#freq('monthly')
  endif
endfunction

" }}}1
function! s:init_buffer_mappings() abort " {{{1
  nnoremap <silent><buffer> <plug>(wiki-code-run)             :WikiCodeRun<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-find-backlinks) :WikiGraphFindBacklinks<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-in)             :WikiGraphIn<cr>
  nnoremap <silent><buffer> <plug>(wiki-graph-out)            :WikiGraphOut<cr>
  nnoremap <silent><buffer> <plug>(wiki-journal-index)        :WikiJournalIndex<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-next)            :WikiLinkNext<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-show)            :WikiLinkShow<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-open)            :WikiLinkOpen<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-open-split)      :WikiLinkOpenSplit<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-prev)            :WikiLinkPrev<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-return)          :WikiLinkReturn<cr>
  nnoremap <silent><buffer> <plug>(wiki-link-toggle)          :WikiLinkToggle<cr>
  nnoremap <silent><buffer> <plug>(wiki-list-moveup)          :WikiListMoveUp<cr>
  nnoremap <silent><buffer> <plug>(wiki-list-movedown)        :WikiListMoveDown<cr>
  nnoremap <silent><buffer> <plug>(wiki-list-toggle)          :WikiListToggle<cr>
  nnoremap <silent><buffer> <plug>(wiki-list-uniq)            :WikiListUniq<cr>
  nnoremap <silent><buffer> <plug>(wiki-list-uniq-local)      :WikiListUniqLocal<cr>
  nnoremap <silent><buffer> <plug>(wiki-list-show-item)       :WikiListShowItem<cr>
  nnoremap <silent><buffer> <plug>(wiki-page-delete)          :WikiPageDelete<cr>
  nnoremap <silent><buffer> <plug>(wiki-page-rename)          :WikiPageRename<cr>
  nnoremap <silent><buffer> <plug>(wiki-page-toc)             :WikiPageToc<cr>
  nnoremap <silent><buffer> <plug>(wiki-page-toc-local)       :WikiPageTocLocal<cr>
  nnoremap <silent><buffer> <plug>(wiki-export)               :WikiExport<cr>
  xnoremap <silent><buffer> <plug>(wiki-export)               :WikiExport<cr>
  nnoremap <silent><buffer> <plug>(wiki-tag-list)             :WikiTagList<cr>
  nnoremap <silent><buffer> <plug>(wiki-tag-reload)           :WikiTagReload<cr>
  nnoremap <silent><buffer> <plug>(wiki-tag-search)           :WikiTagSearch<cr>

  nnoremap <silent><buffer> <plug>(wiki-fzf-toc)              :WikiFzfToc<cr>
  inoremap <silent><buffer> <plug>(wiki-fzf-toc)              <esc>:WikiFzfToc<cr>

  inoremap <silent><buffer> <plug>(wiki-list-toggle)          <esc>:call wiki#list#new_item()<cr>
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
  onoremap <silent><buffer> <plug>(wiki-al) :call wiki#text_obj#list_element(0, 0)<cr>
  xnoremap <silent><buffer> <plug>(wiki-al) :<c-u>call wiki#text_obj#list_element(0, 1)<cr>
  onoremap <silent><buffer> <plug>(wiki-il) :call wiki#text_obj#list_element(1, 0)<cr>
  xnoremap <silent><buffer> <plug>(wiki-il) :<c-u>call wiki#text_obj#list_element(1, 1)<cr>

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
          \ '<plug>(wiki-code-run)' : '<leader>wc',
          \ '<plug>(wiki-graph-find-backlinks)' : '<leader>wb',
          \ '<plug>(wiki-graph-in)' : '<leader>wg',
          \ '<plug>(wiki-graph-out)' : '<leader>wG',
          \ '<plug>(wiki-link-next)' : '<tab>',
          \ '<plug>(wiki-link-prev)' : '<s-tab>',
          \ '<plug>(wiki-link-show)' : '<leader>wll',
          \ '<plug>(wiki-link-open)' : '<cr>',
          \ '<plug>(wiki-link-open-split)' : '<c-w><cr>',
          \ '<plug>(wiki-link-return)' : '<bs>',
          \ '<plug>(wiki-link-toggle)' : '<leader>wf',
          \ '<plug>(wiki-link-toggle-operator)' : 'gl',
          \ '<plug>(wiki-list-toggle)' : '<c-s>',
          \ '<plug>(wiki-list-moveup)' : '<leader>wlk',
          \ '<plug>(wiki-list-movedown)' : '<leader>wlj',
          \ '<plug>(wiki-list-uniq)' : '<leader>wlu',
          \ '<plug>(wiki-list-uniq-local)' : '<leader>wlU',
          \ '<plug>(wiki-list-show-item)' : '<leader>wls',
          \ '<plug>(wiki-page-delete)' : '<leader>wd',
          \ '<plug>(wiki-page-rename)' : '<leader>wr',
          \ '<plug>(wiki-page-toc)' : '<leader>wt',
          \ '<plug>(wiki-page-toc-local)' : '<leader>wT',
          \ '<plug>(wiki-export)' : '<leader>wp',
          \ 'x_<plug>(wiki-export)' : '<leader>wp',
          \ '<plug>(wiki-tag-list)' : '<leader>wsl',
          \ '<plug>(wiki-tag-reload)' : '<leader>wsr',
          \ '<plug>(wiki-tag-search)' : '<leader>wss',
          \ 'i_<plug>(wiki-list-toggle)' : '<c-s>',
          \ 'x_<plug>(wiki-link-toggle-visual)' : '<cr>',
          \ 'o_<plug>(wiki-au)' : 'au',
          \ 'x_<plug>(wiki-au)' : 'au',
          \ 'o_<plug>(wiki-iu)' : 'iu',
          \ 'x_<plug>(wiki-iu)' : 'iu',
          \ 'o_<plug>(wiki-at)' : 'at',
          \ 'x_<plug>(wiki-at)' : 'at',
          \ 'o_<plug>(wiki-it)' : 'it',
          \ 'x_<plug>(wiki-it)' : 'it',
          \ 'o_<plug>(wiki-al)' : 'al',
          \ 'x_<plug>(wiki-al)' : 'al',
          \ 'o_<plug>(wiki-il)' : 'il',
          \ 'x_<plug>(wiki-il)' : 'il',
          \}

    if b:wiki.in_journal
      call extend(l:mappings, {
            \ '<plug>(wiki-journal-prev)' : '<c-p>',
            \ '<plug>(wiki-journal-next)' : '<c-n>',
            \ '<plug>(wiki-journal-copy-tonext)' : '<leader><c-n>',
            \ '<plug>(wiki-journal-toweek)' : '<leader>wu',
            \ '<plug>(wiki-journal-tomonth)' : '<leader>wm',
            \})
    endif
  endif

  call extend(l:mappings, get(g:, 'wiki_mappings_local', {}))

  call wiki#init#apply_mappings_from_dict(l:mappings, '<buffer>')
endfunction

" }}}1

function! s:apply_template() abort " {{{1
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
