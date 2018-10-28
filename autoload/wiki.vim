" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

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
