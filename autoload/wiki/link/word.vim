" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#word#matcher() abort " {{{1
  return extend(
        \ wiki#link#_template#matcher(),
        \ deepcopy(s:matcher))
endfunction

" }}}1


let s:matcher = {
      \ 'rx' : wiki#rx#word,
      \ 'scheme' : '',
      \ 'type' : 'word',
      \}

function! s:matcher.toggle_template(text, _) abort " {{{1
  " This template returns a wiki template for the provided word(s). It does
  " a smart search for likely candidates and if there is no unique match, it
  " asks for target link.

  " Allow custom map of text -> url, text (without extension)
  if !empty(g:wiki_map_text_to_link)
        \ && (type(g:wiki_map_text_to_link) == v:t_func
        \     || exists('*' . g:wiki_map_text_to_link))
    let [l:url, l:text] = call(g:wiki_map_text_to_link, [a:text])
  else
    let l:url = a:text
    let l:text = a:text
  endif

  " Append extension if wanted
  let l:url_root = l:url
  if !empty(b:wiki.link_extension)
        \ && strcharpart(l:url, strchars(l:url)-1) !=# '/'
    let l:url .= b:wiki.link_extension
    let l:url_actual = l:url
  else
    let l:url_actual = l:url . '.' . b:wiki.extension
  endif


  " First try local page
  if filereadable(wiki#paths#s(printf('%s/%s', expand('%:p:h'), l:url_actual)))
    return wiki#link#template(l:url, l:text)
  endif

  " Next try at wiki root
  let l:root = get(b:wiki, 'root', expand('%:p:h'))
  if filereadable(wiki#paths#s(printf('%s/%s', l:root, l:url_actual)))
    return wiki#link#template('/' . l:url, l:text)
  endif

  " Finally we see if there are completable candidates
  let l:candidates = map(
        \ glob(printf(
        \     '%s/%s*.%s', l:root, l:url_root, b:wiki.extension), 0, 1),
        \ 'fnamemodify(v:val, '':t:r'')')

  " Solve trivial cases first
  if len(l:candidates) == 0
    return wiki#link#template(
          \ (b:wiki.in_journal ? '/' : '') . l:url, l:text)
  endif

  " Select with menu
  let l:new = l:url . ' (NEW PAGE)'
  let l:choice = wiki#ui#choose(l:candidates + [l:new])
  redraw!
  return empty(l:choice) ? l:url : (
        \ l:choice ==# l:new
        \   ? wiki#link#template(l:url, l:text)
        \   : wiki#link#template('/' . l:choice, ''))
endfunction

" }}}1
