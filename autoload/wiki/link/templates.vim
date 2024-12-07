" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#templates#adoc_xref_bracket(url, text, ...) abort
  let l:parts = split(a:url, '#')
  let l:anchors = len(l:parts) > 1
        \ ? join(l:parts[1:], '#')
        \ : ''

  " Ensure there's an extension
  let l:url = l:parts[0]
  if l:url !~# '\.adoc$'
    let l:url .= '.adoc'
  endif
  let l:url .= '#' . l:anchors

  return printf('<<%s,%s>>', l:url, empty(a:text) ? a:url : a:text)
endfunction

function! wiki#link#templates#adoc_xref_inline(url, text, ...) abort
  let l:parts = split(a:url, '#')
  let l:anchors = len(l:parts) > 1
        \ ? join(l:parts[1:], '#')
        \ : ''

  " Ensure there's an extension
  let l:url = l:parts[0]
  if l:url !~# '\.adoc$'
    let l:url .= '.adoc'
  endif
  let l:url .= '#' . l:anchors

  return printf('xref:' . (l:url =~# '\s' ? '[%s]' : '%s') . '[%s]',
        \ l:url, empty(a:text) ? a:url : a:text)
endfunction

function! wiki#link#templates#md(url, text, ...) abort
  return printf('[%s](%s)', empty(a:text) ? a:url : a:text, a:url)
endfunction

function! wiki#link#templates#org(url, text, ...) abort
  return empty(a:text) || a:text ==# a:url || a:text ==# a:url[1:]
        \ ? '[[' . a:url . ']]'
        \ : '[[' . a:url . '][' . a:text . ']]'
endfunction

function! wiki#link#templates#wiki(url, text, ...) abort
  return empty(a:text) || a:text ==# a:url || a:text ==# a:url[1:]
        \ ? '[[' . a:url . ']]'
        \ : '[[' . a:url . '|' . a:text . ']]'
endfunction

function! wiki#link#templates#ref_target(url, id, ...) abort
  let l:id = empty(a:id) ? wiki#ui#input(#{info: 'Input id: '}) : a:id
  return '[' . l:id . ']: ' . a:url
endfunction

function! wiki#link#templates#word(text, ...) abort
  " This template returns a wiki template for the provided word(s). It does
  " a smart search for likely candidates and if there is no unique match, it
  " asks for target link.
  let l:creator = wiki#link#get_creator()

  " Apply url transformer if available
  let l:url = a:text
  if has_key(l:creator, 'url_transform')
    try
      let l:url = l:creator.url_transform(a:text)
    catch
      call wiki#log#warn('There was a problem with the url transformer!')
    endtry
  endif

  " Append extension if wanted
  let l:url_root = l:url
  if !empty(l:creator.url_extension)
        \ && strcharpart(l:url, strchars(l:url)-1) !=# '/'
    let l:url .= l:creator.url_extension
    let l:url_actual = l:url
  else
    let l:url_actual = l:url . '.' . b:wiki.extension
  endif

  " First try local page
  let l:root_current = expand('%:p:h')
  if filereadable(wiki#paths#s(printf('%s/%s', l:root_current, l:url_actual)))
    return wiki#link#template(l:url, a:text)
  endif

  " If we are inside the journal, then links should by default point to the
  " wiki root.
  if get(b:wiki, 'in_journal')
    let l:root = get(b:wiki, 'root', l:root_current)
    let l:prefix = resolve(l:root) ==# resolve(l:root_current) ? '' : '/'

    " Check if target matches at wiki root
    if filereadable(wiki#paths#s(printf('%s/%s', l:root, l:url_actual)))
      return wiki#link#template(l:prefix . l:url, a:text)
    endif
  else
    let l:root = l:root_current
    let l:prefix = ''
  endif

  " Finally we see if there are completable candidates
  let l:candidates = map(
        \ glob(printf(
        \     '%s/%s*.%s', l:root, l:url_root, b:wiki.extension), 0, 1),
        \ { _, x -> fnamemodify(x, ':t:r') })

  " Solve trivial cases first
  if len(l:candidates) == 0
    return wiki#link#template(l:prefix . l:url, a:text)
  endif

  " Select with menu
  let l:new = l:url . ' (NEW PAGE)'
  let l:choice = wiki#ui#select(l:candidates + [l:new])

  return empty(l:choice) ? "" : (
        \ l:choice ==# l:new
        \   ? wiki#link#template(l:url, a:text)
        \   : wiki#link#template(l:prefix . l:choice, ''))
endfunction
