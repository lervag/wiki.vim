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
        \ 'content': strpart(getline('.'), l:c1-1, l:c2-l:c1+1),
        \ 'filename': expand('%:p'),
        \ 'pos_end': [l:lnum, l:c2],
        \ 'pos_start': [l:lnum, l:c1],
        \}

  return self.create_link(l:match)
endfunction

"}}}1
function! s:matcher.create_link(match) dict abort " {{{1
  let l:match = extend(a:match, deepcopy(self))

  " Get link text
  let l:match.text = ''
  if has_key(self, 'rx_text')
    let [l:text, l:c1, l:c2] = s:matchstrpos(l:match.content, self.rx_text)
    if !empty(l:text)
      let l:match.text = l:text
      let l:match.text_pos_start = [l:match.pos_start[0], l:match.pos_start[1] + l:c1]
      let l:match.text_pos_end = [l:match.pos_start[0], l:match.pos_start[1] + l:c2 - 1]
    endif
  endif

  " Get link url
  let l:match.url = l:match.content
  if has_key(self, 'rx_url')
    let [l:url, l:c1, l:c2] = s:matchstrpos(l:match.content, self.rx_url)
    if !empty(l:url)
      let l:match.url = l:url
      let l:match.url_pos_start = [l:match.pos_start[0], l:match.pos_start[1] + l:c1]
      let l:match.url_pos_end = [l:match.pos_start[0], l:match.pos_start[1] + l:c2 - 1]
    endif
  endif
  let l:match.url_raw = l:match.url

  " Matcher specific url parsing
  call l:match.parse_url()

  " Add toggle function
  if !has_key(l:match, 'toggle_template')
        \ && has_key(g:wiki_link_toggles, self.type)
    let l:match.toggle_template = function(g:wiki_link_toggles[self.type])
  endif

  " Clean up
  silent! unlet l:match.rx
  silent! unlet l:match.rx_url
  silent! unlet l:match.rx_text
  silent! unlet l:match.create_link
  silent! unlet l:match.match_at_cursor
  silent! unlet l:match.parse_url

  " Return the parsed link
  return s:link.new(l:match)
endfunction

"}}}1
function! s:matcher.parse_url() dict abort " {{{1
  if !empty(get(self, 'scheme', '')) && empty(matchstr(self.url, '^\w\+:'))
    let self.url = self.scheme . ':' . self.url
  endif
endfunction

" }}}1


let s:link = {}
function! s:link.new(match) dict abort " {{{1
  let l:link = extend(deepcopy(self), a:match)
  unlet l:link.new

  " Extend link with URL handler
  if !has_key(l:link, 'follow') && l:link.type !=# 'word'
    let l:link = wiki#url#extend(l:link)
  endif

  return l:link
endfunction

" }}}1
function! s:link.replace(text) dict abort " {{{1
  let l:line = getline(self.pos_start[0])
  call setline(self.pos_start[0],
        \   strpart(l:line, 0, self.pos_start[1]-1)
        \ . a:text
        \ . strpart(l:line, self.pos_end[1]))
endfunction

" }}}1
function! s:link.pprint() dict abort " {{{1
  let l:out = {
        \ 'type': self.type,
        \ 'scheme': get(self, 'scheme', 'NONE'),
        \ 'text': get(self, 'text', ''),
        \ 'url': self.url,
        \ 'raw_url': self.url_raw,
        \ 'raw': self.content,
        \ 'follow': string(get(self, 'follow', '')),
        \ 'toggle_template': string(get(self, 'toggle_template', '')),
        \}
  if l:out.raw_url ==# l:out.url
    unlet l:out.raw_url
  endif
  if l:out.raw ==# l:out.url
    unlet l:out.raw
  endif
  if empty(l:out.text)
    unlet l:out.text
  endif
  if empty(l:out.follow)
    unlet l:out.follow
  endif
  if empty(l:out.toggle_template)
    unlet l:out.toggle_template
  endif
  return l:out
endfunction

" }}}1
function! s:link.toggle() dict abort " {{{1
  if empty(self.url_raw) | return | endif

  " Apply link template from toggle (abort if empty!)
  let l:new = self.toggle_template(self.url_raw, self.text)
  if empty(l:new) | return | endif

  call self.replace(l:new)
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
