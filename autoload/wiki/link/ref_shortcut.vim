" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#ref_shortcut#matcher() abort " {{{1
  return extend(
        \ wiki#link#_template#matcher(),
        \ deepcopy(s:matcher))
endfunction

" }}}1


let s:matcher = {
      \ 'type': 'ref_shortcut',
      \ 'rx': wiki#rx#link_ref_shortcut,
      \ 'rx_target': '\[\zs' . wiki#rx#reflabel . '\ze\]',
      \}

function! s:matcher.parse_url() dict abort " {{{1
  let self.id = matchstr(self.content, self.rx_target)

  " Locate target url
  let self.lnum_target = searchpos('^\s*\[' . self.id . '\]: ', 'nW')[0]
  if self.lnum_target == 0
    function! self.toggle_template(_url, _text) abort dict
      call wiki#log#warn(
            \ 'Could not locate reference ',
            \ ['ModeMsg', self.url]
            \)
    endfunction
  endif

  let l:line = getline(self.lnum_target)
  let self.url = matchstr(l:line, g:wiki#rx#url)
  if !empty(self.url) | return | endif

  let self.url = matchstr(l:line, '^\s*\[' . self.id . '\]: \s*\zs.*\ze\s*$')
  let l:url = wiki#url#parse(self.url)
  if l:url.scheme ==# 'wiki' && filereadable(l:url.path)
    return
  endif

  " The url is not recognized, so we add a fallback follower to link to the
  " reference position.
  unlet self.url
  function! self.follow(...) abort dict
    normal! m'
    call cursor(self.lnum_target, 1)
  endfunction
endfunction

" }}}1
function! s:matcher.toggle_template(_url, _text) dict abort " {{{1
  return wiki#link#md#template(self.url, self.id)
endfunction

" }}}1
