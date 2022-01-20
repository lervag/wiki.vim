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
  let self.lnum_target = searchpos('^\[' . self.id . '\]: ', 'nW')[0]
  if self.lnum_target == 0
    function! self.toggle_template(_url, _text) abort dict
      call wiki#log#warn(
            \ 'Could not locate reference ',
            \ ['ModeMsg', self.url]
            \)
    endfunction
  endif

  let self.url = matchstr(getline(self.lnum_target), g:wiki#rx#url)
  if !empty(self.url) | return | endif


  " The url is not recognized, so we add a fallback follower to link to the
  " reference position.
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
