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
  return empty(l:choice) ? l:url : (
        \ l:choice ==# l:new
        \   ? wiki#link#template(l:url, a:text)
        \   : wiki#link#template(l:prefix . l:choice, ''))
endfunction

" }}}1
