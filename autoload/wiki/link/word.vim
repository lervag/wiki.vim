" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#link#word#matcher() abort " {{{1
  return deepcopy(s:matcher)
endfunction

" }}}1
function! wiki#link#word#template(url, text) abort dict " {{{1
  "
  " This template returns a wiki template for the provided word(s). It does
  " a smart search for likely candidates and if there is no unique match, it
  " asks for target link.
  "
  let l:url = a:url
  let l:text = empty(a:text) ? l:url : a:text

  " Allow to map text -> url
  if !empty(g:wiki_map_link_create) && exists('*' . g:wiki_map_link_create)
    let l:url = call(g:wiki_map_link_create, [a:url])
  endif

  "
  " First try local page
  "
  if filereadable(printf('%s/%s.%s', expand('%:p:h'), l:url, b:wiki.extension))
    return wiki#link#template(l:url, l:text)
  endif

  "
  " Next try at wiki root
  "
  if filereadable(printf('%s/%s.%s', b:wiki.root, l:url, b:wiki.extension))
    return wiki#link#template('/' . l:url, l:text)
  endif

  "
  " Finally we see if there are completable candidates
  "
  let l:candidates = map(
        \ glob(printf('%s/%s*.%s', b:wiki.root, l:url, b:wiki.extension), 0, 1),
        \ 'fnamemodify(v:val, '':t:r'')')

  "
  " Solve trivial cases first
  "
  if len(l:candidates) == 0
    return wiki#link#template((b:wiki.in_journal ? '/' : '') . l:url, l:text)
  elseif len(l:candidates) == 1
    return wiki#link#template('/' . l:candidates[0], '')
  endif

  " Create menu
  let l:list_menu = []
  for l:i in range(len(l:candidates))
    let l:list_menu += [['[' . (l:i + 1) . '] ', l:candidates[l:i]]]
  endfor
  let l:list_menu += [['[n] ', 'New page at wiki root']]
  let l:list_menu += [['[x] ', 'Abort']]

  "
  " Finally we ask for user input to choose desired candidate
  "
  while 1
    redraw

    " Print the menu; fancy printing is not possible with operator mapping
    if exists('wiki#link#word#operator')
      echo join(map(copy(l:list_menu), 'v:val[0] . v:val[1]'), "\n")
    else
      for [l:key, l:val] in l:list_menu
        echohl ModeMsg
        echo l:key
        echohl NONE
        echon l:val
      endfor
    endif

    let l:choice = nr2char(getchar())
    if l:choice ==# 'x'
      redraw!
      return l:url
    endif

    if l:choice ==# 'n'
      redraw!
      return wiki#link#template(l:url, l:text)
    endif

    if str2nr(l:choice) > 0
      try
        let l:cand = l:candidates[l:choice - 1]
        redraw!
        return wiki#link#template('/' . l:cand, '')
      catch
        continue
      endtry
    endif
  endwhile
endfunction

" }}}1

let s:matcher = {
      \ 'type' : 'word',
      \ 'toggle' : function('wiki#link#word#template'),
      \ 'rx' : wiki#rx#word,
      \}

function! s:matcher.parse(link) abort dict " {{{1
  let a:link.scheme = ''
  let a:link.url = a:link.full . get(b:wiki, 'link_extension', '')
  if !empty(b:wiki.link_extension)
    let a:link.text = a:link.full
  endif

  return a:link
endfunction

" }}}1
