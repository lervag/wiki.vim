" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

let g:wiki#link#definitions#wiki = {
      \ 'type': 'wiki',
      \ 'rx': g:wiki#rx#link_wiki,
      \ 'rx_url': '\[\[\zs\/\?[^\\\]]\{-}\ze\%(|[^\\\]]\{-}\)\?\]\]',
      \ 'rx_text': '\[\[\/\?[^\\\]]\{-}|\zs[^\\\]]\{-}\ze\]\]',
      \}

let g:wiki#link#definitions#adoc_xref_bracket = {
      \ 'type': 'adoc_xref_bracket',
      \ 'rx': g:wiki#rx#link_adoc_xref_bracket,
      \ 'rx_url': '<<\zs\%([^,>]\{-}\ze,[^>]\{-}\|[^>]\{-}\ze\)>>',
      \ 'rx_text': '<<[^,>]\{-},\zs[^>]\{-}\ze>>',
      \}

let g:wiki#link#definitions#adoc_xref_inline = {
      \ 'type': 'adoc_xref_inline',
      \ 'rx': g:wiki#rx#link_adoc_xref_inline,
      \ 'rx_url': '\<xref:\%(\[\zs[^]]\+\ze\]\|\zs[^[]\+\ze\)\[[^]]*\]',
      \ 'rx_text': '\<xref:\%(\[[^]]\+\]\|[^[]\+\)\[\zs[^]]*\ze\]',
      \}

let g:wiki#link#definitions#adoc_link = {
      \ 'type': 'adoc_link',
      \ 'rx': g:wiki#rx#link_adoc_link,
      \ 'rx_url': '\<link:\%(\[\zs[^]]\+\ze\]\|\zs[^[]\+\ze\)\[[^]]\+\]',
      \ 'rx_text': '\<link:\%(\[[^]]\+\]\|[^[]\+\)\[\zs[^]]\+\ze\]',
      \}

let g:wiki#link#definitions#md_fig = {
      \ 'type': 'md_fig',
      \ 'rx': g:wiki#rx#link_md_fig,
      \ 'rx_url': '!\[[^\\\[\]]\{-}\](\zs[^\\]\{-}\ze)',
      \ 'rx_text': '!\[\zs[^\\\[\]]\{-}\ze\]([^\\]\{-})',
      \ '__transformer': { u, t, _ -> printf('![%s](%s)', empty(t) ? u : t, u) },
      \}

let g:wiki#link#definitions#md = {
      \ 'type': 'md',
      \ 'rx': g:wiki#rx#link_md,
      \ 'rx_url': '\[[^[\]]\{-}\](\zs[^\\]\{-}\ze)',
      \ 'rx_text': '\[\zs[^[\]]\{-}\ze\]([^\\]\{-})',
      \}

let g:wiki#link#definitions#org = {
      \ 'type' : 'org',
      \ 'rx' : g:wiki#rx#link_org,
      \ 'rx_url' : '\[\[\zs\/\?[^\\\]]\{-}\ze\]\%(\[[^\\\]]\{-}\]\)\?\]',
      \ 'rx_text' : '\[\[\/\?[^\\\]]\{-}\]\[\zs[^\\\]]\{-}\ze\]\]',
      \}

let g:wiki#link#definitions#ref_target = {
      \ 'type': 'ref_target',
      \ 'rx': wiki#rx#link_ref_target,
      \ 'rx_url': '\[' . wiki#rx#reflabel . '\]:\s\+\zs' . wiki#rx#url,
      \ 'rx_text': '^\s*\[\zs' . wiki#rx#reflabel . '\ze\]',
      \ '__transformer': function('wiki#link#templates#ref_target'),
      \}

let g:wiki#link#definitions#reference = {
      \ 'type': 'reference',
      \ 'rx': wiki#rx#link_reference,
      \ 'rx_url': '\[\zs' . wiki#rx#reflabel . '\ze\]',
      \ '__scheme': 'reference',
      \ '__transformer': { _u, _t, l -> wiki#link#template#md(l.url, l.id) },
      \}

let g:wiki#link#definitions#ref_collapsed = extend(
      \ deepcopy(wiki#link#definitions#reference), {
      \ 'rx': g:wiki#rx#link_ref_collapsed,
      \ 'rx_url': '\[\zs' . g:wiki#rx#reflabel . '\ze\]\[\]',
      \ 'rx_text': '\[\zs' . g:wiki#rx#reflabel . '\ze\]\[\]',
      \})

let g:wiki#link#definitions#ref_full = extend(
      \ deepcopy(wiki#link#definitions#reference), {
      \ 'rx': g:wiki#rx#link_ref_full,
      \ 'rx_url':
      \   '\['    . g:wiki#rx#reftext   . '\]'
      \ . '\[\zs' . g:wiki#rx#reflabel . '\ze\]',
      \ 'rx_text':
      \   '\[\zs' . g:wiki#rx#reftext   . '\ze\]'
      \ . '\['    . g:wiki#rx#reflabel . '\]',
      \})

let g:wiki#link#definitions#url = {
      \ 'type': 'url',
      \ 'rx': g:wiki#rx#url,
      \}

let g:wiki#link#definitions#cite = {
      \ 'type': 'cite',
      \ 'rx': wiki#rx#link_cite,
      \ 'rx_url': wiki#rx#link_cite_url,
      \}

let g:wiki#link#definitions#date = {
      \ 'type': 'date',
      \ 'rx': g:wiki#rx#date,
      \}

let g:wiki#link#definitions#word = {
      \ 'type' : 'word',
      \ 'rx' : wiki#rx#word,
      \ '__transformer': function('wiki#link#templates#word'),
      \}


" wiki#link#definitions#all is an ordered list of definitions used by
" wiki#link#get() to detect a link at the cursor. Similarly,
" wiki#link#definitions#all_real is an ordered list of definitions used by
" wiki#link#get_all() to get all links in a given file.
"
" Notice that the order is important! The order between the wiki, md, and org
" definitions is especially tricky! This is because wiki and org links are
" equivalent when they lack a description: [[url]]. Thus, the order specified
" here means wiki.vim will always match [[url]] as a wiki link and never as an
" org link. This is not a problem for links with a description, though, since
" they differ: [[url|description]] vs [[url][description]], respectively.
let g:wiki#link#definitions#all = [
      \ g:wiki#link#definitions#wiki,
      \ g:wiki#link#definitions#adoc_xref_bracket,
      \ g:wiki#link#definitions#adoc_xref_inline,
      \ g:wiki#link#definitions#adoc_link,
      \ g:wiki#link#definitions#md_fig,
      \ g:wiki#link#definitions#md,
      \ g:wiki#link#definitions#org,
      \ g:wiki#link#definitions#ref_target,
      \ g:wiki#link#definitions#reference,
      \ g:wiki#link#definitions#ref_collapsed,
      \ g:wiki#link#definitions#ref_full,
      \ g:wiki#link#definitions#url,
      \ g:wiki#link#definitions#cite,
      \ g:wiki#link#definitions#date,
      \ g:wiki#link#definitions#word,
      \]

let g:wiki#link#definitions#all_real = [
      \ g:wiki#link#definitions#wiki,
      \ g:wiki#link#definitions#adoc_xref_bracket,
      \ g:wiki#link#definitions#adoc_xref_inline,
      \ g:wiki#link#definitions#adoc_link,
      \ g:wiki#link#definitions#md_fig,
      \ g:wiki#link#definitions#md,
      \ g:wiki#link#definitions#org,
      \ g:wiki#link#definitions#ref_target,
      \ g:wiki#link#definitions#url,
      \ g:wiki#link#definitions#cite,
      \]
