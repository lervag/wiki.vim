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

function! s:matcher.toggle_template(words, _text) abort " {{{1
  " This template returns a wiki template for the provided word(s). It does
  " a smart search for likely candidates and if there is no unique match, it
  " asks for target link.

  " Allow map from word -> url (without extension)
  if !empty(g:wiki_map_link_create) && (type(g:wiki_map_link_create) == 2 || exists('*' . g:wiki_map_link_create))
    let l:url_target = call(g:wiki_map_link_create, [a:words])
  else
    let l:url_target = a:words
  endif

  " Append extension if wanted
  let l:url_root = l:url_target
  if !empty(b:wiki.link_extension)
    let l:url_target .= b:wiki.link_extension
    let l:url_actual = l:url_target
  else
    let l:url_actual = l:url_target . '.' . b:wiki.extension
  endif


  " First try local page
  if filereadable(wiki#paths#s(printf('%s/%s', expand('%:p:h'), l:url_actual)))
    return wiki#link#template(l:url_target, a:words)
  endif

  " Next try at wiki root
  if filereadable(wiki#paths#s(printf('%s/%s', b:wiki.root, l:url_actual)))
    return wiki#link#template('/' . l:url_target, a:words)
  endif

  " Finally we see if there are completable candidates
  let l:candidates = map(
        \ glob(printf(
        \     '%s/%s*.%s', b:wiki.root, l:url_root, b:wiki.extension), 0, 1),
        \ 'fnamemodify(v:val, '':t:r'')')

  " Solve trivial cases first
  if len(l:candidates) == 0
    return wiki#link#template(
          \ (b:wiki.in_journal ? '/' : '') . l:url_target, a:words)
  endif

  " Select with menu
  let l:new = l:url_target . ' (NEW PAGE)'
  let l:choice = wiki#ui#choose(l:candidates + [l:new])
  redraw!
  return empty(l:choice) ? l:url_target : (
        \ l:choice ==# l:new
        \   ? wiki#link#template(l:url_target, a:words)
        \   : wiki#link#template('/' . l:choice, ''))
endfunction

" }}}1
