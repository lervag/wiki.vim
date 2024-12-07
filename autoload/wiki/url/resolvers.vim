" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#url#resolvers#adoc(url) abort
  let l:url = deepcopy(a:url)

  let l:parts = split(l:url.stripped, '#', 1)
  if len(l:parts) == 1 && l:parts[0] !~# '\.adoc$'
    let l:url.path = ''
    let l:url.anchor = l:parts[0]
  else
    let l:root = empty(l:url.origin)
          \ ? wiki#get_root()
          \ : fnamemodify(l:url.origin, ':p:h')
    let l:url.path = wiki#paths#s(printf('%s/%s', l:root, l:parts[0]))
    let l:url.anchor = get(l:parts, 1, '')
  endif

  return l:url
endfunction

function! wiki#url#resolvers#file(url) abort
  let l:url = deepcopy(a:url)

  let l:url.ext = fnamemodify(l:url.stripped, ':e')
  if l:url.stripped[0] ==# '/'
    let l:url.path = l:url.stripped
  elseif l:url.stripped =~# '^\~'
    let l:url.path = simplify(fnamemodify(l:url.stripped, ':p'))
  else
    let l:url.path = simplify(
          \ fnamemodify(l:url.origin, ':p:h') . '/' . l:url.stripped)
  endif

  return l:url
endfunction

function! wiki#url#resolvers#journal(url) abort
  let l:matches = matchlist(a:url.stripped, '\v([^#]*)%(#(.*))?')
  let l:date = get(l:matches, 1, 'N/A')
  let l:anchor = get(l:matches, 3, '')

  let [l:node, l:frq] = wiki#journal#date_to_node(l:date)
  if empty(l:node)
    call wiki#log#warn(
          \ 'Could not parse journal URL!',
          \ 'URL:    ' . a:url.stripped,
          \ 'Date:   ' . l:date,
          \ 'Anchor: ' . l:anchor,
          \)
    return {}
  endif

  let l:url = deepcopy(a:url)
  let l:url.scheme = 'wiki'
  let l:url.anchor = l:anchor

  if empty(g:wiki_journal.root)
    let l:url.stripped = printf('/%s/%s', g:wiki_journal.name, l:node)
    let l:url.url = 'wiki:' . l:url.stripped
    let l:url.path =
          \ wiki#url#utils#resolve_path(l:url.stripped, l:url.origin)
  else
    let l:url.stripped = wiki#paths#s(g:wiki_journal.root . '/' . l:node)
    let l:url.url = 'wiki:' . l:url.stripped
    let l:url.path = wiki#url#utils#add_extension(l:url.stripped)
  endif

  return l:url
endfunction

function! wiki#url#resolvers#man(url) abort
  let l:url = deepcopy(a:url)

  let l:url.path = 'man://' . matchstr(l:url.url, 'man:\(\/\/\)\?\zs[^ (]*')

  let l:section = matchstr(l:url.url, '-\zs\d$')
  if !empty(l:section)
    let l:url.path .= '(' . l:section . ')'
  endif

  return l:url
endfunction

function! wiki#url#resolvers#reference(url) abort
  let l:id = a:url.stripped
  let l:lnum_target = searchpos('^\s*\[' . l:id . '\]: ', 'nW')[0]
  if l:lnum_target == 0
    call wiki#log#warn(
          \ 'Could not locate reference ',
          \ ['ModeMsg', a:url.stripped]
          \)
    return {}
  endif

  let l:line = getline(l:lnum_target)
  let l:url_string = matchstr(l:line, g:wiki#rx#url)
  if !empty(l:url_string)
    return wiki#url#resolve(l:url_string)
  endif

  " The reference definition is found, but the URL was not trivially
  " recognized. Use a less strict regex and try again, but only accept wiki
  " schemed urls to existing files.
  let l:url_string = matchstr(l:line, '^\s*\[' . l:id . '\]: \s*\zs.*\ze\s*$')
  let l:url = wiki#url#resolve(l:url_string)
  if l:url.scheme ==# 'wiki' && filereadable(l:url.path)
    return l:url
  endif

  " The url is not recognized, so we add a fallback handler that will take us
  " to the reference position.
  return extend(deepcopy(a:url), {
        \ 'scheme': 'refbad',
        \ 'lnum': l:lnum_target,
        \ 'original': a:url
        \})
endfunction

function! wiki#url#resolvers#wiki(url) abort
  let l:url = deepcopy(a:url)

  let l:url.anchor = wiki#url#utils#extract_anchor(l:url.stripped)

  let l:path = split(l:url.stripped, '#', 1)[0]
  let l:url.path = wiki#url#utils#resolve_path(l:path, l:url.origin)

  return l:url
endfunction

function! wiki#url#resolvers#md(url) abort
  let l:url = deepcopy(a:url)

  let l:anchor = wiki#url#utils#extract_anchor(l:url.stripped)
  let l:url.anchor = wiki#url#utils#url_decode(l:anchor)

  let l:path = split(l:url.stripped, '#', 1)[0]
  let l:path = wiki#url#utils#url_decode(l:path)
  let l:url.path = wiki#url#utils#resolve_path(l:path, l:url.origin)

  return l:url
endfunction
