" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let g:wiki#link#def#wiki = {
      \ 'type': 'wiki',
      \ 'rx': g:wiki#rx#link_wiki,
      \ 'rx_url': '\[\[\zs\/\?[^\\\]]\{-}\ze\%(|[^\\\]]\{-}\)\?\]\]',
      \ 'rx_text': '\[\[\/\?[^\\\]]\{-}|\zs[^\\\]]\{-}\ze\]\]',
      \}

let g:wiki#link#def#adoc_xref_bracket = {
      \ 'type': 'adoc_xref_bracket',
      \ 'rx': g:wiki#rx#link_adoc_xref_bracket,
      \ 'rx_url': '<<\zs\%([^,>]\{-}\ze,[^>]\{-}\|[^>]\{-}\ze\)>>',
      \ 'rx_text': '<<[^,>]\{-},\zs[^>]\{-}\ze>>',
      \}

let g:wiki#link#def#adoc_xref_inline = {
      \ 'type': 'adoc_xref_inline',
      \ 'rx': g:wiki#rx#link_adoc_xref_inline,
      \ 'rx_url': '\<xref:\%(\[\zs[^]]\+\ze\]\|\zs[^[]\+\ze\)\[[^]]*\]',
      \ 'rx_text': '\<xref:\%(\[[^]]\+\]\|[^[]\+\)\[\zs[^]]*\ze\]',
      \}

let g:wiki#link#def#adoc_link = {
      \ 'type': 'adoc_link',
      \ 'rx': g:wiki#rx#link_adoc_link,
      \ 'rx_url': '\<link:\%(\[\zs[^]]\+\ze\]\|\zs[^[]\+\ze\)\[[^]]\+\]',
      \ 'rx_text': '\<link:\%(\[[^]]\+\]\|[^[]\+\)\[\zs[^]]\+\ze\]',
      \}

let g:wiki#link#def#md_fig = {
      \ 'type': 'md_fig',
      \ 'rx': g:wiki#rx#link_md_fig,
      \ 'rx_url': '!\[[^\\\[\]]\{-}\](\zs[^\\]\{-}\ze)',
      \ 'rx_text': '!\[\zs[^\\\[\]]\{-}\ze\]([^\\]\{-})',
      \ '__transformer': { u, t, _ -> printf('![%s](%s)', empty(t) ? u : t, u) },
      \}

let g:wiki#link#def#md = {
      \ 'type': 'md',
      \ 'rx': g:wiki#rx#link_md,
      \ 'rx_url': '\[[^[\]]\{-}\](\zs[^\\]\{-}\ze)',
      \ 'rx_text': '\[\zs[^[\]]\{-}\ze\]([^\\]\{-})',
      \}

let g:wiki#link#def#org = {
      \ 'type' : 'org',
      \ 'rx' : g:wiki#rx#link_org,
      \ 'rx_url' : '\[\[\zs\/\?[^\\\]]\{-}\ze\]\%(\[[^\\\]]\{-}\]\)\?\]',
      \ 'rx_text' : '\[\[\/\?[^\\\]]\{-}\]\[\zs[^\\\]]\{-}\ze\]\]',
      \}

let g:wiki#link#def#ref_definition = {
      \ 'type': 'ref_definition',
      \ 'rx': wiki#rx#link_ref_definition,
      \ 'rx_url': '\[' . wiki#rx#reflabel . '\]:\s\+\zs' . wiki#rx#url,
      \ 'rx_text': '^\s*\[\zs' . wiki#rx#reflabel . '\ze\]',
      \ '__transformer': function('wiki#link#template#ref_target'),
      \}

let g:wiki#link#def#ref_shortcut = {
      \ 'type': 'ref_shortcut',
      \ 'rx': wiki#rx#link_ref_shortcut,
      \ 'rx_target': '\[\zs' . wiki#rx#reflabel . '\ze\]',
      \ '__transformer': { _u, _t, l -> wiki#link#template#md(l.url, l.id) },
      \}
function! wiki#link#def#ref_shortcut.post_init_hook(link) dict abort " {{{1
  let a:link.id = matchstr(a:link.content, self.rx_target)

  " Locate target url
  let a:link.lnum_target = searchpos('^\s*\[' . a:link.id . '\]: ', 'nW')[0]
  if a:link.lnum_target == 0
    function! a:link.__transformer(_url, _text, link) abort dict
      call wiki#log#warn(
            \ 'Could not locate reference ',
            \ ['ModeMsg', a:link.url]
            \)
    endfunction
  endif

  let l:line = getline(a:link.lnum_target)
  let a:link.url = matchstr(l:line, g:wiki#rx#url)
  if !empty(a:link.url) | return | endif

  let a:link.url = matchstr(l:line, '^\s*\[' . a:link.id . '\]: \s*\zs.*\ze\s*$')
  let l:url = wiki#url#parse(a:link.url)
  if l:url.scheme ==# 'wiki' && filereadable(l:url.path)
    return
  endif

  " The url is not recognized, so we add a fallback follower to link to the
  " reference position.
  unlet a:link.url
  function! a:link.follow(...) abort dict
    normal! m'
    call cursor(a:link.lnum_target, 1)
  endfunction
endfunction

" }}}1

let g:wiki#link#def#ref_collapsed = extend(
      \ deepcopy(wiki#link#def#ref_shortcut), {
      \ 'rx': g:wiki#rx#link_ref_collapsed,
      \ 'rx_target': '\[\zs' . g:wiki#rx#reflabel . '\ze\]\[\]',
      \ 'rx_text': '\[\zs' . g:wiki#rx#reflabel . '\ze\]\[\]',
      \})

let g:wiki#link#def#ref_full = extend(
      \ deepcopy(wiki#link#def#ref_shortcut), {
      \ 'rx': g:wiki#rx#link_ref_full,
      \ 'rx_target':
      \   '\['    . g:wiki#rx#reftext   . '\]'
      \ . '\[\zs' . g:wiki#rx#reflabel . '\ze\]',
      \ 'rx_text':
      \   '\[\zs' . g:wiki#rx#reftext   . '\ze\]'
      \ . '\['    . g:wiki#rx#reflabel . '\]',
      \})

let g:wiki#link#def#url = {
      \ 'type': 'url',
      \ 'rx': g:wiki#rx#url,
      \}

let g:wiki#link#def#cite = {
      \ 'type': 'cite',
      \ 'rx': wiki#rx#link_cite,
      \ 'rx_url': wiki#rx#link_cite_url,
      \}

let g:wiki#link#def#date = {
      \ 'type': 'date',
      \ 'rx': g:wiki#rx#date,
      \}

let g:wiki#link#def#word = {
      \ 'type' : 'word',
      \ 'rx' : wiki#rx#word,
      \ '__transformer': function('wiki#link#template#word'),
      \}


" wiki#link#def#all is an ordered list of definitions used by wiki#link#get()
" to detect a link at the cursor. Similarly, wiki#link#def#all_real is an
" ordered list of definitions used by wiki#link#get_all() to get all links in
" a given file.
"
" Notice that the order is important! The order between the wiki, md, and org
" definitions is especially tricky! This is because wiki and org links are
" equivalent when they lack a description: [[url]]. Thus, the order specified
" here means wiki.vim will always match [[url]] as a wiki link and never as an
" org link. This is not a problem for links with a description, though, since
" they differ: [[url|description]] vs [[url][description]], respectively.
let g:wiki#link#def#all = [
      \ g:wiki#link#def#wiki,
      \ g:wiki#link#def#adoc_xref_bracket,
      \ g:wiki#link#def#adoc_xref_inline,
      \ g:wiki#link#def#adoc_link,
      \ g:wiki#link#def#md_fig,
      \ g:wiki#link#def#md,
      \ g:wiki#link#def#org,
      \ g:wiki#link#def#ref_definition,
      \ g:wiki#link#def#ref_shortcut,
      \ g:wiki#link#def#ref_collapsed,
      \ g:wiki#link#def#ref_full,
      \ g:wiki#link#def#url,
      \ g:wiki#link#def#cite,
      \ g:wiki#link#def#date,
      \ g:wiki#link#def#word,
      \]

let g:wiki#link#def#all_real = [
      \ g:wiki#link#def#wiki,
      \ g:wiki#link#def#adoc_xref_bracket,
      \ g:wiki#link#def#adoc_xref_inline,
      \ g:wiki#link#def#adoc_link,
      \ g:wiki#link#def#md_fig,
      \ g:wiki#link#def#md,
      \ g:wiki#link#def#org,
      \ g:wiki#link#def#ref_definition,
      \ g:wiki#link#def#url,
      \ g:wiki#link#def#cite,
      \]
