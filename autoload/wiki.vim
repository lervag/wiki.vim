" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

function! wiki#init() abort " {{{1
  call s:init_global_options()
  call s:init_global_commands()
  call s:init_global_mappings()
endfunction

" }}}1
function! wiki#init_buffer() abort " {{{1
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
  setlocal comments =f:*\ TODO:,fb:*\ [\ ],fb:*\ [x],fb:*
  setlocal comments+=f:-\ TODO:,fb:-\ [\ ],fb:-\ [x],fb:-
  setlocal comments+=nb:>
  let &l:commentstring = '// %s'
  setlocal formatoptions-=o
  setlocal formatoptions+=n
  let &l:formatlistpat = '\v^\s*%(\d|\l|i+)\.\s'

  augroup wiki
    autocmd!
    autocmd BufWinEnter *.wiki setlocal conceallevel=2
  augroup END

  let b:wiki = extend(get(b:, 'wiki', {}),
        \ {
        \ 'in_journal' : stridx(
        \   resolve(expand('%:p')),
        \   resolve(printf('%s/%s', wiki#get_root(), g:wiki_journal))) == 0
        \ })

  call s:init_buffer_commands()
  call s:init_buffer_mappings()
  call s:init_prefill()
endfunction

" }}}1

function! wiki#goto_index() abort " {{{1
  call wiki#url#parse('wiki:/index').open()
endfunction

" }}}1
" {{{1 function! wiki#reload()
let s:file = expand('<sfile>')
if get(s:, 'reload_guard', 1)
  function! wiki#reload() abort
    let s:reload_guard = 0
    let l:foldmethod = &l:foldmethod

    " Reload autoload scripts
    for l:file in [s:file]
          \ + split(globpath(fnamemodify(s:file, ':h'), '**/*.vim'), '\n')
      execute 'source' l:file
    endfor

    " Reload plugin
    if exists('g:wiki_loaded')
      unlet g:wiki_loaded
      runtime plugin/wiki.vim
    endif

    " Reload ftplugin and syntax
    if &filetype ==# 'wiki'
      unlet b:did_ftplugin
      runtime ftplugin/wiki.vim

      if get(b:, 'current_syntax', '') ==# 'wiki'
        unlet b:current_syntax
        runtime syntax/wiki.vim
      endif
    endif

    if exists('#User#WikiReloadPost')
      doautocmd <nomodeline> User WikiReloadPost
    endif

    let &l:foldmethod = l:foldmethod
    unlet s:reload_guard
  endfunction
endif

" }}}1

function! wiki#get_root() abort " {{{1
  " The root is cached for the current buffer
  if exists('b:wiki.root') | return b:wiki.root | endif

  " Search directory tree for an 'index.wiki' file
  let l:root = get(
        \ map(findfile('index.wiki', '.;', -1), 'fnamemodify(v:val, '':p:h'')'),
        \ -1, '')

  " Try globally specified wiki
  if empty(l:root)
    let l:root = get(g:, 'wiki_root', '')
    if !empty(l:root)
      let l:root = fnamemodify(l:root, ':p')
      if !isdirectory(l:root)
        echoerr 'Please set g:wiki_root!'
        return ''
      endif
    endif
  endif

  " Cache the found root
  let b:wiki = extend(get(b:, 'wiki', {}), { 'root' : l:root })

  return l:root
endfunction

" }}}1


function! s:init_global_commands() abort " {{{1
  command! WikiIndex   call wiki#goto_index()
  command! WikiReload  call wiki#reload()
  command! WikiJournal call wiki#journal#make_note()
endfunction

" }}}1
function! s:init_global_mappings() abort " {{{1
  nnoremap <silent> <plug>(wiki-index)   :WikiIndex<cr>
  nnoremap <silent> <plug>(wiki-journal) :WikiJournal<cr>
  nnoremap <silent> <plug>(wiki-reload)  :WikiReload<cr>

  let l:mappings = get(g:, 'wiki_mappings_use_defaults', 1)
        \ ? {
        \ '<plug>(wiki-index)' : '<leader>ww',
        \ '<plug>(wiki-journal)' : '<leader>w<leader>w',
        \ '<plug>(wiki-reload)' : '<leader>wx',
        \} : {}
  call extend(l:mappings, get(g:, 'wiki_mappings_global', {}))

  call s:init_mappings_from_dict(l:mappings, '')
endfunction

" }}}1
function! s:init_global_options() abort " {{{1
  let g:wiki_journal = 'journal'
endfunction

" }}}1
function! s:init_buffer_commands() abort " {{{1
  command! -buffer WikiCodeRun            call wiki#u#run_code_snippet()
  command! -buffer WikiGraphFindBacklinks call wiki#graph#find_backlinks()
  command! -buffer WikiGraphIn            call wiki#graph#to_current()
  command! -buffer WikiGraphOut           call wiki#graph#from_current()
  command! -buffer WikiLinkNext           call wiki#nav#next_link()
  command! -buffer WikiLinkOpen           call wiki#link#open()
  command! -buffer WikiLinkOpenSplit      call wiki#link#open('vsplit')
  command! -buffer WikiLinkPrev           call wiki#nav#prev_link()
  command! -buffer WikiLinkReturn         call wiki#nav#return()
  command! -buffer WikiLinkToggle         call wiki#link#toggle()
  command! -buffer WikiListTottle         call wiki#list#toggle()
  command! -buffer WikiPageDelete         call wiki#page#delete()
  command! -buffer WikiPageRename         call wiki#page#rename()
  command! -buffer WikiPageToc            call wiki#page#create_toc()

  if b:wiki.in_journal
    command! -buffer -count=1 WikiJournalPrev       call wiki#journal#go(-<count>)
    command! -buffer -count=1 WikiJournalNext       call wiki#journal#go(<count>)
    command! -buffer          WikiJournalCopyToNext call wiki#journal#copy_note()
    command! -buffer          WikiJournalToWeek     call wiki#journal#go_to_week()
    command! -buffer          WikiJournalToMonth    call wiki#journal#go_to_month()
  endif
endfunction

" }}}1
function! s:init_buffer_mappings() abort " {{{1
  nnoremap <buffer> <plug>(wiki-code-run)             :WikiCodeRun<cr>
  nnoremap <buffer> <plug>(wiki-graph-find-backlinks) :WikiGraphFindBacklinks<cr>
  nnoremap <buffer> <plug>(wiki-graph-in)             :WikiGraphIn<cr>
  nnoremap <buffer> <plug>(wiki-graph-out)            :WikiGraphOut<cr>
  nnoremap <buffer> <plug>(wiki-link-next)            :WikiLinkNext<cr>
  nnoremap <buffer> <plug>(wiki-link-open)            :WikiLinkOpen<cr>
  nnoremap <buffer> <plug>(wiki-link-open-split)      :WikiLinkOpenSplit<cr>
  nnoremap <buffer> <plug>(wiki-link-prev)            :WikiLinkPrev<cr>
  nnoremap <buffer> <plug>(wiki-link-return)          :WikiLinkReturn<cr>
  nnoremap <buffer> <plug>(wiki-link-toggle)          :WikiLinkToggle<cr>
  nnoremap <buffer> <plug>(wiki-list-toggle)          :WikiListTottle<cr>
  nnoremap <buffer> <plug>(wiki-page-delete)          :WikiPageDelete<cr>
  nnoremap <buffer> <plug>(wiki-page-rename)          :WikiPageRename<cr>
  nnoremap <buffer> <plug>(wiki-page-toc)             :WikiPageToc<cr>

  inoremap <buffer><expr> <plug>(wiki-list-toggle)          wiki#list#new_line_bullet()
  xnoremap <buffer>       <plug>(wiki-link-toggle-visual)   :<c-u>call wiki#link#toggle_visual()<cr>
  nnoremap <buffer>       <plug>(wiki-link-toggle-operator) :set opfunc=wiki#link#toggle_operator<cr>g@

  onoremap <buffer> <plug>(wiki-al) :call wiki#text_obj#link(0)<cr>
  xnoremap <buffer> <plug>(wiki-al) :<c-u>call wiki#text_obj#link(0)<cr>
  onoremap <buffer> <plug>(wiki-il) :call wiki#text_obj#link(1)<cr>
  xnoremap <buffer> <plug>(wiki-il) :<c-u>call wiki#text_obj#link(1)<cr>
  onoremap <buffer> <plug>(wiki-at) :call wiki#text_obj#link_text(0)<cr>
  xnoremap <buffer> <plug>(wiki-at) :<c-u>call wiki#text_obj#link_text(0)<cr>
  onoremap <buffer> <plug>(wiki-it) :call wiki#text_obj#link_text(1)<cr>
  xnoremap <buffer> <plug>(wiki-it) :<c-u>call wiki#text_obj#link_text(1)<cr>
  onoremap <buffer> <plug>(wiki-ac) :call wiki#text_obj#code(0)<cr>
  xnoremap <buffer> <plug>(wiki-ac) :<c-u>call wiki#text_obj#code(0)<cr>
  onoremap <buffer> <plug>(wiki-ic) :call wiki#text_obj#code(1)<cr>
  xnoremap <buffer> <plug>(wiki-ic) :<c-u>call wiki#text_obj#code(1)<cr>

  if b:wiki.in_journal
    nnoremap <buffer> <plug>(wiki-journal-prev)        :WikiJournalPrev<cr>
    nnoremap <buffer> <plug>(wiki-journal-next)        :WikiJournalNext<cr>
    nnoremap <buffer> <plug>(wiki-journal-copy-tonext) :WikiJournalCopyToNext<cr>
    nnoremap <buffer> <plug>(wiki-journal-toweek)      :WikiJournalToWeek<cr>
    nnoremap <buffer> <plug>(wiki-journal-tomonth)     :WikiJournalToMonth<cr>
  endif


  let l:mappings = {}
  if get(g:, 'wiki_mappings_use_defaults', 1)
    let l:mappings = {
          \ '<plug>(wiki-code-run)' : '<leader>wc',
          \ '<plug>(wiki-graph-find-backlinks)' : '<leader>wb',
          \ '<plug>(wiki-graph-in)' : '<leader>wg',
          \ '<plug>(wiki-graph-out)' : '<leader>wG',
          \ '<plug>(wiki-link-next)' : '<tab>',
          \ '<plug>(wiki-link-open)' : '<cr>',
          \ '<plug>(wiki-link-open-split)' : '<c-cr>',
          \ '<plug>(wiki-link-prev)' : '<s-tab>',
          \ '<plug>(wiki-link-return)' : '<bs>',
          \ '<plug>(wiki-link-toggle)' : '<leader>wf',
          \ '<plug>(wiki-link-toggle-operator)' : 'gl',
          \ '<plug>(wiki-list-toggle)' : '<c-s>',
          \ '<plug>(wiki-page-delete)' : '<leader>wd',
          \ '<plug>(wiki-page-rename)' : '<leader>wr',
          \ '<plug>(wiki-page-toc)' : '<leader>wt',
          \ 'i_<plug>(wiki-list-toggle)' : '<c-s>',
          \ 'x_<plug>(wiki-link-toggle-visual)' : '<cr>',
          \ 'o_<plug>(wiki-al)' : 'al',
          \ 'x_<plug>(wiki-al)' : 'al',
          \ 'o_<plug>(wiki-il)' : 'il',
          \ 'x_<plug>(wiki-il)' : 'il',
          \ 'o_<plug>(wiki-at)' : 'at',
          \ 'x_<plug>(wiki-at)' : 'at',
          \ 'o_<plug>(wiki-it)' : 'it',
          \ 'x_<plug>(wiki-it)' : 'it',
          \ 'o_<plug>(wiki-ac)' : 'ac',
          \ 'x_<plug>(wiki-ac)' : 'ac',
          \ 'o_<plug>(wiki-ic)' : 'ic',
          \ 'x_<plug>(wiki-ic)' : 'ic',
          \}

    if b:wiki.in_journal
      call extend(l:mappings, {
            \ '<plug>(wiki-journal-prev)' : '<c-j>',
            \ '<plug>(wiki-journal-next)' : '<c-k>',
            \ '<plug>(wiki-journal-copy-tonext)' : '<leader>wk',
            \ '<plug>(wiki-journal-toweek)' : '<leader>wu',
            \ '<plug>(wiki-journal-tomonth)' : '<leader>wm',
            \})
    endif
  endif

  call extend(l:mappings, get(g:, 'wiki_mappings_local', {}))

  call s:init_mappings_from_dict(l:mappings, '<buffer>')
endfunction

" }}}1

function! s:init_mappings_from_dict(dict, arg) abort " {{{1
  for [l:rhs, l:lhs] in items(a:dict)
    if l:rhs[0] !=# '<'
      let l:mode = l:rhs[0]
      let l:rhs = l:rhs[2:]
    else
      let l:mode = 'n'
    endif

    if hasmapto(l:rhs, l:mode)
      continue
    endif

    execute l:mode . 'map <silent>' . a:arg l:lhs l:rhs
  endfor
endfunction
  
  " }}}1

function! s:init_prefill() abort " {{{1
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
