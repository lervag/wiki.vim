" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#rx#surrounded(word, chars) abort " {{{1
  return '\%(^\|\s\|[[:punct:]]\)\zs'
        \ . escape(a:chars, '*')
        \ . a:word
        \ . escape(join(reverse(split(a:chars, '\zs')), ''), '*')
        \ . '\ze\%([[:punct:]]\|\s\|$\)'
endfunction

" }}}1

let wiki#rx#word = '[^[:blank:]!"$%&''()*+,:;<=>?\[\]\\^`{}]\+'
let wiki#rx#pre_beg = '^\s*```'
let wiki#rx#pre_end = '^\s*```\s*$'
let wiki#rx#super = '\^[^^`]\+\^'
let wiki#rx#sub = ',,[^,`]\+,,'
let wiki#rx#list_define = '::\%(\s\|$\)'
let wiki#rx#comment = '^\s*%%.*$'
let wiki#rx#todo = '\C\<\%(TODO\|STARTED\|FIXME\)\>:\?'
let wiki#rx#done = '\C\<\%(OK\|DONE\|FIXED\)\>:\?'
let wiki#rx#header_md_atx = '^#\{1,6}\s*[^#].*'
let wiki#rx#header_md_atx_items = '^\(#\{1,6}\)\s*\([^#].*\)\s*$'
let wiki#rx#header_org = '^\*\{1,6}\s*[^\*].*'
let wiki#rx#header_org_items = '^\(\*\{1,6}\)\s*\([^\*].*\)\s*$'
let wiki#rx#header_adoc = '^=\{1,6}\s*[^=].*'
let wiki#rx#header_adoc_items = '^\(=\{1,6}\)\s*\([^=].*\)\s*$'
let wiki#rx#bold = wiki#rx#surrounded(
      \ '[^*`[:space:]]\%([^*`]*[^*`[:space:]]\)\?', '*')
let wiki#rx#italic = wiki#rx#surrounded(
      \ '[^_`[:space:]]\%([^_`]*[^_`[:space:]]\)\?', '_')
let wiki#rx#date = '\d\d\d\d-\d\d-\d\d'
let wiki#rx#url =
      \ '\%(\<\l\+:\%(\/\/\)\?[^ \t()\[\]|]\+'
      \ . '\|'
      \ . '<\zs\l\+:\%(\/\/\)\?[^>]\+\ze>\)'
let wiki#rx#reftext = '[^\\\[\]]\{-}'
let wiki#rx#reflabel = '\%(\d\+\|\a[-_. [:alnum:]]\+\|\^\w\+\)'
let wiki#rx#link_adoc_link = '\<link:\%(\[[^]]\+\]\|[^[]\+\)\[[^]]*\]'
let wiki#rx#link_adoc_xref_bracket = '<<[^>]\+>>'
let wiki#rx#link_adoc_xref_inline = '\<xref:\%(\[[^]]\+\]\|[^[]\+\)\[[^]]*\]'
let wiki#rx#link_md = '\[[^[\]]\{-}\]([^\\]\{-})'
let wiki#rx#link_md_fig = '!' . wiki#rx#link_md
let wiki#rx#link_org = '\[\[\/\?[^\\\]]\{-}\]\%(\[[^\\\]]\{-}\]\)\?\]'
let wiki#rx#link_ref_shortcut = '[\]\[]\@<!\[' . wiki#rx#reflabel . '\][\]\[]\@!'
let wiki#rx#link_ref_collapsed = '[\]\[]\@<!\[' . wiki#rx#reflabel . '\]\[\][\]\[]\@!'
let wiki#rx#link_ref_full =
      \ '[\]\[]\@<!'
      \ . '\[' . wiki#rx#reftext   . '\]'
      \ . '\[' . wiki#rx#reflabel . '\]'
      \ . '[\]\[]\@!'
let wiki#rx#link_ref_definition =
      \ '^\s*\[' . wiki#rx#reflabel . '\]:\s\+' . wiki#rx#url
let wiki#rx#link_shortcite = '\%(\s\|^\|\[\)\zs@[-_.a-zA-Z0-9]\+[-_a-zA-Z0-9]'
let wiki#rx#link_wiki = '\[\[\/\?[^\\\]]\{-}\%(|[^\\\]]\{-}\)\?\]\]'
let wiki#rx#link = join([
      \ wiki#rx#link_wiki,
      \ wiki#rx#link_adoc_link,
      \ wiki#rx#link_adoc_xref_bracket,
      \ wiki#rx#link_adoc_xref_inline,
      \ '!\?' . wiki#rx#link_md,
      \ wiki#rx#link_org,
      \ wiki#rx#link_ref_definition,
      \ wiki#rx#link_ref_shortcut,
      \ wiki#rx#link_ref_full,
      \ wiki#rx#url,
      \ wiki#rx#link_shortcite,
      \], '\|')
