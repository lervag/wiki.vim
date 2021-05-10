" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#_template#matcher() abort " {{{1
  return deepcopy(s:matcher)
endfunction

" }}}1


let s:matcher = {}
function! s:matcher.match_at_cursor() dict abort " {{{1
  let l:lnum = line('.')

  " Seach backwards for current regex
  let l:c1 = searchpos(self.rx, 'ncb', l:lnum)[1]
  if l:c1 == 0 | return {} | endif

  " Ensure that the cursor is positioned on top of the match
  let l:c1e = searchpos(self.rx, 'ncbe', l:lnum)[1]
  if l:c1e >= l:c1 && l:c1e < col('.') | return {} | endif

  " Find the end of the match
  let l:c2 = searchpos(self.rx, 'nce', l:lnum)[1]
  if l:c2 == 0 | return {} | endif

  let l:c2 = wiki#u#cnum_to_byte(l:c2)

  let l:match = {
        \ 'full': strpart(getline('.'), l:c1-1, l:c2-l:c1+1),
        \ 'filename': expand('%:p'),
        \ 'lnum': l:lnum,
        \ 'c1': l:c1,
        \ 'c2': l:c2,
        \}

  return self.create_link(l:match)
endfunction

"}}}1
function! s:matcher.create_link(link) dict abort " {{{1
  let a:link.type = self.type

  " Get link text
  let a:link.text = ''
  if has_key(self, 'rx_text')
    let [l:text, l:c1, l:c2] = s:matchstrpos(a:link.full, self.rx_text)
    if !empty(l:text)
      let a:link.text = l:text
      let a:link.text_c1 = a:link.c1 + l:c1
      let a:link.text_c2 = a:link.c1 + l:c2 - 1
    endif
  endif

  " Get link url
  let a:link.url = a:link.full
  if has_key(self, 'rx_url')
    let [l:url, l:c1, l:c2] = s:matchstrpos(a:link.full, self.rx_url)
    if !empty(l:url)
      let a:link.url = l:url
      let a:link.url_c1 = a:link.c1 + l:c1
      let a:link.url_c2 = a:link.c1 + l:c2 - 1
    endif
  endif

  " Add toggler if applicable
  if has_key(self, 'toggle')
    let a:link.toggle = self.toggle
  elseif has_key(g:wiki_link_toggles, self.type)
    let a:link.toggle = function(g:wiki_link_toggles[self.type])
  endif

  " Return the parsed link
  return self.parse(a:link)
endfunction

"}}}1
function! s:matcher.parse(link) dict abort " {{{1
  if has_key(self, 'scheme') && empty(matchstr(a:link.url, '\v^\w+:'))
    let a:link.url = self.scheme . ':' . a:link.url
  endif

  return wiki#url#extend(a:link)
endfunction

" }}}1


function! s:matchstrpos(...) abort " {{{1
  if exists('*matchstrpos')
    return call('matchstrpos', a:000)
  else
    let [l:expr, l:pat] = a:000[:1]

    let l:pos = match(l:expr, l:pat)
    if l:pos < 0
      return ['', -1, -1]
    else
      let l:match = matchstr(l:expr, l:pat)
      return [l:match, l:pos, l:pos+strlen(l:match)]
    endif
  endif
endfunction

" }}}1
