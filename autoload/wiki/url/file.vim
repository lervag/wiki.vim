" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#file#handler(url) abort " {{{1
  let l:handler = deepcopy(s:handler)

  let l:handler.url = a:url.url
  let l:handler.ext = fnamemodify(a:url.stripped, ':e')
  if a:url.stripped[0] ==# '/'
    let l:handler.path = a:url.stripped
  elseif a:url.stripped =~# '\~\w*\/'
    let l:handler.path = simplify(fnamemodify(a:url.stripped, ':p'))
  else
    let l:handler.path = simplify(
          \ fnamemodify(a:url.origin, ':p:h') . '/' . a:url.stripped)
  endif

  return l:handler
endfunction

" }}}1


let s:handler = {}
function! s:handler.follow(...) abort dict " {{{1
  try
    if call(get(g:, 'wiki_file_handler', ''), a:000, self)
      return
    endif
  catch /E117:/
    " Pass
  endtry

  let l:cmd = get(g:wiki_viewer, self.ext, g:wiki_viewer._)
  if l:cmd ==# ':edit'
    silent execute 'edit' fnameescape(self.path)
  else
    call wiki#jobs#run(l:cmd . ' ' . shellescape(self.path) . '&')
  endif
endfunction

" }}}1
