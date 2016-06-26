" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#init() " {{{1
  let g:vimwiki = {}
  let g:vimwiki.root = g:vimwiki_path
  let g:vimwiki.diary = g:vimwiki_path . 'journal/'
  let g:vimwiki.rx = {}

  "
  " Define mappings
  "
  nnoremap <silent> <leader>ww         :call vimwiki#page#goto_index()<cr>
  nnoremap <silent> <leader>wx         :call vimwiki#reload()<cr>
  nnoremap <silent> <leader>w<leader>w :call vimwiki#diary#make_note()<cr>
endfunction

" }}}1
function! vimwiki#init_buffer() " {{{1
  "
  " Set default options
  "

  let b:vimwiki = {}
  let g:vimwiki_listsyms = ' .oOX'

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
  " setlocal formatoptions-=cr02
  " setlocal formatoptions+=n

  "Create 'formatlistpat'
  let &formatlistpat = g:vimwiki.rx.lst_item

  if exists('+conceallevel')
    setlocal conceallevel=2
  endif

  command! -buffer          VimwikiTOC            call vimwiki#page#create_toc()
  command! -buffer -range   VimwikiToggleListItem call vimwiki#lst#toggle_cb(<line1>, <line2>)

  "
  " Keybindings
  "
  nnoremap <silent><buffer> <tab>      :call vimwiki#link#find_next()<cr>
  nnoremap <silent><buffer> <s-tab>    :call vimwiki#link#find_prev()<cr>
  nnoremap <silent><buffer> <bs>       :call vimwiki#link#go_back()<cr>

  nnoremap <silent><buffer> <leader>wd :call vimwiki#page#delete()<cr>
  nnoremap <silent><buffer> <leader>wr :call vimwiki#page#rename()<cr>

  nnoremap <silent><buffer> <cr>       :call vimwiki#link#follow()<cr>
  nnoremap <silent><buffer> <c-cr>     :call vimwiki#link#follow('vsplit')<cr>

  nnoremap <silent><buffer> <c-space>  :VimwikiToggleListItem<cr>

  nnoremap <silent><buffer> <leader>wl :call vimwiki#page#backlinks()<cr>

  vnoremap <silent><buffer> <cr>      :<c-u>call vimwiki#link#normalize(1)<cr>
  vnoremap <silent><buffer> <c-space> :VimwikiToggleListItem<cr>


  " Journal settings
  if expand('%:p') =~# 'wiki\/journal'
    setlocal foldlevel=0
    nnoremap <silent><buffer> <c-j> :<c-u>call vimwiki#diary#go(-v:count1)<cr>
    nnoremap <silent><buffer> <c-k> :<c-u>call vimwiki#diary#go(v:count1)<cr>
    nnoremap <silent><buffer> <leader>wk :call vimwiki#diary#copy_note()<cr>
  else
    nnoremap <silent><buffer> <c-j>      :call vimwiki#diary#make_note()<cr>
    nnoremap <silent><buffer> <c-k>      :call vimwiki#diary#make_note()<cr>
  endif
endfunction

" }}}1

" {{{1 function! vimwiki#reload()
let s:file = expand('<sfile>')
if !exists('s:reloading_script')
  function! vimwiki#reload()
    let s:reloading_script = 1

    " Reload autoload scripts
    for l:file in [s:file]
          \ + split(globpath(fnamemodify(s:file, ':r'), '*.vim'), '\n')
      execute 'source' l:file
    endfor

    " Reload plugin
    if exists('g:vimwiki_loaded')
      unlet g:vimwiki_loaded
      runtime plugin/vimwiki.vim
    endif

    " Reload ftplugin and syntax
    if &filetype == 'vimwiki'
      unlet b:did_ftplugin
      runtime ftplugin/vimwiki.vim

      if get(b:, 'current_syntax', '') ==# 'vimwiki'
        unlet b:current_syntax
        runtime syntax/vimwiki.vim
      endif
    endif

    unlet s:reloading_script
  endfunction
endif

" }}}1
function! vimwiki#define_regexes() " {{{
  let g:vimwiki_markdown_header_search = '^\s*\(#\{1,6}\)\([^#].*\)$'
  let g:vimwiki_markdown_header_match = '^\s*\(#\{1,6}\)#\@!\s*__Header__\s*$'
  let g:vimwiki_markdown_bold_search = '\%(^\|\s\|[[:punct:]]\)\@<=\*\zs\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)\ze\*\%([[:punct:]]\|\s\|$\)\@='
  let g:vimwiki_markdown_bold_match = '\%(^\|\s\|[[:punct:]]\)\@<=\*__Text__\*\%([[:punct:]]\|\s\|$\)\@='
  let g:vimwiki_markdown_wikilink = '\[\[\zs[^\\\]|]\+\ze\%(|[^\\\]]\+\)\?\]\]'
  let g:vimwiki_markdown_tag_search = '\(^\|\s\)\zs:\([^:''[:space:]]\+:\)\+\ze\(\s\|$\)'
  let g:vimwiki_markdown_tag_match = '\(^\|\s\):\([^:''[:space:]]\+:\)*__Tag__:\([^:[:space:]]\+:\)*\(\s\|$\)'

  let g:vimwiki_bullet_types = { '-':0, '*':0, '+':0 }
  let g:vimwiki_number_types = ['1.']
  let g:vimwiki_list_markers = ['-', '*', '+', '1.']
  call vimwiki#lst#setup_marker_infos()

  let g:vimwiki.rx.url_web = '\w\+:\%(//\)\?' . '\S\{-1,}\%(([^ \t()]*)\)\='
  let g:vimwiki.rx.link_web = '\<'. g:vimwiki.rx.url_web . '\S*'
  let g:vimwiki.rx.link_web_url = g:vimwiki.rx.link_web
  let g:vimwiki.rx.link_web_text = ''

  let g:vimwiki.rx.H = '#'

  let g:vimwiki.rx.lst_item_no_checkbox = '^\s*\%(\('.g:vimwiki.rx.lst_bullet.'\)\|\('.g:vimwiki.rx.lst_number.'\)\)\s'
  let g:vimwiki.rx.lst_item = g:vimwiki.rx.lst_item_no_checkbox . '\+\%(\[\(['.g:vimwiki_listsyms.']\)\]\s\)\?'

  let g:vimwiki.rx.preStart = '^\s*```'
  let g:vimwiki.rx.preEnd = '^\s*```\s*$'

  let g:vimwiki.rx.mathStart = '^\s*\$\$'
  let g:vimwiki.rx.mathEnd = '^\s*\$\$\s*$'

  let g:vimwiki.rx.italic = '\%(^\|\s\|[[:punct:]]\)\@<='.
        \'_'.
        \'\%([^_`[:space:]][^_`]*[^_`[:space:]]\|[^_`[:space:]]\)'.
        \'_'.
        \'\%([[:punct:]]\|\s\|$\)\@='
  let g:vimwiki.rx.boldItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
        \'\*_'.
        \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
        \'_\*'.
        \'\%([[:punct:]]\|\s\|$\)\@='
  let g:vimwiki.rx.italicBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
        \'_\*'.
        \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
        \'\*_'.
        \'\%([[:punct:]]\|\s\|$\)\@='
  let g:vimwiki.rx.code = '`[^`]\+`'
  let g:vimwiki.rx.delText = '\~\~[^~`]\+\~\~'
  let g:vimwiki.rx.superScript = '\^[^^`]\+\^'
  let g:vimwiki.rx.subScript = ',,[^,`]\+,,'
  let g:vimwiki.rx.HR = '^\s*-\{4,}\s*$'
  let g:vimwiki.rx.listDefine = '::\%(\s\|$\)'
  let g:vimwiki.rx.comment = '^\s*%%.*$'
endfunction

" }}}1

" vim: fdm=marker sw=2
