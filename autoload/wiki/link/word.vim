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
function! wiki#link#word#template(_url, text) abort dict " {{{1
  " This template returns a wiki template for the provided word(s). It does
  " a smart search for likely candidates and if there is no unique match, it
  " asks for target link.

  " Allow map from text -> url (without extension)
  if !empty(g:wiki_map_link_create) && exists('*' . g:wiki_map_link_create)
    let l:url_target = call(g:wiki_map_link_create, [a:text])
  else
    let l:url_target = a:text
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
  if filereadable(printf('%s/%s', expand('%:p:h'), l:url_actual))
    return wiki#link#template(l:url_target, a:text)
  endif

  " Next try at wiki root
  if filereadable(printf('%s/%s', b:wiki.root, l:url_actual))
    return wiki#link#template('/' . l:url_target, a:text)
  endif

  " Finally we see if there are completable candidates
  let l:candidates = map(
        \ glob(printf(
        \     '%s/%s*.%s', b:wiki.root, l:url_root, b:wiki.extension), 0, 1),
        \ 'fnamemodify(v:val, '':t:r'')')

  " Solve trivial cases first
  if len(l:candidates) == 0
    return wiki#link#template(
          \ (b:wiki.in_journal ? '/' : '') . l:url_target, a:text)
  endif

  " Select with menu
  let l:new = l:url_target . ' (NEW PAGE)'
  let l:choice = wiki#ui#choose(l:candidates + [l:new])
  redraw!
  return empty(l:choice) ? l:url_target : (
        \ l:choice ==# l:new
        \   ? wiki#link#template(l:url_target, a:text)
        \   : wiki#link#template('/' . l:choice, ''))
endfunction

" }}}1


let s:matcher = {
      \ 'scheme' : '',
      \ 'type' : 'word',
      \ 'toggle' : function('wiki#link#word#template'),
      \ 'rx' : wiki#rx#word,
      \}

function! s:matcher.parse_url() abort dict " {{{1
  let self.text = self.content
  let self.url = ''
endfunction

" }}}1
