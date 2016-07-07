" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:current_syntax') | finish | endif
let b:current_syntax = 'vimwiki'

syntax spell toplevel
syntax sync minlines=100

" {{{1 Main syntax

let s:table_groups = []

" {{{2 Define link groups

"
" This adds the top level syntax matching for link types and creates link
" clusters
"
for [s:group, s:rx; s:contained] in [
      \ ['VimwikiLinkUrl',  'url',  'VimwikiLinkUrlConceal'],
      \ ['VimwikiLinkWiki', 'wiki', 'VimwikiLinkWikiConceal'],
      \ ['VimwikiLinkRef', 'ref_simple'],
      \ ['VimwikiLinkRefTarget', 'ref_target', 'VimwikiLinkUrl'],
      \ ['VimwikiLinkRef', 'ref', 'VimwikiLinkRefConceal'],
      \ ['VimwikiLinkMd', 'md', 'VimwikiLinkMdConceal'],
      \ ['VimwikiLinkDate', 'date'],
      \]
  " Links in general
  execute 'syntax cluster VimwikiLink  add=' . s:group
  execute 'syntax match' s:group
        \ '/' . vimwiki#link#get_matcher_opt(s:rx, 'rx') . '/'
        \ 'display contains=@NoSpell'
        \ . (empty(s:contained) ? '' : ',' . join(s:contained, ','))

  " Links in tables
  call filter(s:contained, 'v:val !~# ''Conceal''')
  call add(s:table_groups, [s:group . 'T', s:group])
  execute 'syntax match' s:group . 'T'
        \ '/' . vimwiki#link#get_matcher_opt(s:rx, 'rx') . '/'
        \ 'display contained contains=@NoSpell'
        \ . (empty(s:contained) ? '' : ',' . join(s:contained, ','))
endfor
unlet s:group s:rx s:contained

syntax match VimwikiLinkUrlConceal
      \ `\%(///\=[^/ \t]\+/\)\zs\S\+\ze\%([/#?]\w\|\S\{15}\)`
      \ cchar=~ contained transparent contains=NONE conceal

syntax match VimwikiLinkWikiConceal /\[\[\/\?\%([^\\\]]\{-}|\)\?/
      \ contained transparent contains=NONE conceal
syntax match VimwikiLinkWikiConceal /\]\]/
      \ contained transparent contains=NONE conceal

syntax match VimwikiLinkMdConceal /\[/
      \ contained transparent contains=NONE conceal
syntax match VimwikiLinkMdConceal /\]([^\\]\{-})/
      \ contained transparent contains=NONE conceal

syntax match VimwikiLinkRefConceal /[\]\[]\@<!\[/
      \ contained transparent contains=NONE conceal
syntax match VimwikiLinkRefConceal /\]\[.*\]/
      \ contained transparent contains=NONE conceal

" }}}2
" {{{2 Define header groups

for s:i in range(1,6)
  execute 'syntax match VimwikiHeader' . s:i
        \ . ' /^#\{' . s:i . '}\zs[^#].*/'
        \ . ' contains=VimwikiTodo,VimwikiHeaderChar,'
        \ .           'VimwikiCode,@VimwikiLink,@Spell'
endfor
syntax match VimwikiHeaderChar contained /^#\+/

" }}}2
" {{{2 Define various groups

execute 'syntax match VimwikiTodo /' . vimwiki#rx#todo() . '/'

syntax match VimwikiList /^\s*[-*]\s\+/
syntax match VimwikiList /::\%(\s\|$\)/
syntax match VimwikiListTodo /^\s*[-*] \[ \]/
syntax match VimwikiListTodoDone /^\s*[-*] \[[xX]\]/ contains=@VimwikiLink,@Spell

syntax match VimwikiEqIn  /\$[^$`]\+\$/ contains=VimwikiEqInChar
syntax match VimwikiEqInT /\$[^$`]\+\$/ contained

execute 'syntax match VimwikiBold /'.vimwiki#rx#bold().'/ contains=VimwikiBoldChar,@Spell'
execute 'syntax match VimwikiBoldT /'.vimwiki#rx#bold().'/ contained contains=VimwikiBoldCharT,@Spell'

execute 'syntax match VimwikiItalic /'.vimwiki#rx#italic().'/ contains=VimwikiItalicChar,@Spell'
execute 'syntax match VimwikiItalicT /'.vimwiki#rx#italic().'/ contained contains=VimwikiItalicCharT,@Spell'

syntax match VimwikiCode /`[^`]\+`/ contains=VimwikiCodeChar
syntax match VimwikiCodeT /`[^`]\+`/ contained contains=VimwikiCodeCharT

syntax match VimwikiLine /^\s*-\{4,}\s*$/

syntax region VimwikiQuote start=/^>\s\+/ end=/^$/ contains=VimwikiQuoteChar

syntax match number  /\d\+\.\d\+/
syntax match version /\d\+\.\d\+\(\.\d\)\+/
syntax match time    /\d\d:\d\d/

syntax match VimwikiEqInChar       contained /\$/   conceal
syntax match VimwikiBoldChar       contained /*/    conceal
syntax match VimwikiItalicChar     contained /_/    conceal
syntax match VimwikiCodeChar       contained /`/    conceal
syntax match VimwikiQuoteChar      contained /^>/   conceal cchar= 

" }}}2
" {{{2 Define table groups

syntax match VimwikiTableRow /^\s*|.\+|\s*$/
      \ transparent contains=@VimwikiInTable,@Spell
syntax match VimwikiCellSeparator
      \ /\%(|\)\|\%(-\@<=+\-\@=\)\|\%([|+]\@<=-\+\)/ contained

call add(s:table_groups, ['VimwikiCellSeparator', ''])
call add(s:table_groups, ['VimwikiTodo', ''])
call add(s:table_groups, ['VimwikiBoldT', 'VimwikiBold'])
call add(s:table_groups, ['VimwikiItalicT', 'VimwikiItalic'])
call add(s:table_groups, ['VimwikiCodeT', 'VimwikiCode'])
call add(s:table_groups, ['VimwikiEqInT', 'VimwikiEqIn'])

for [s:g1, s:g2] in s:table_groups
  execute 'syntax cluster VimwikiInTable add=' . s:g1
  if !empty(s:g2)
    execute 'highlight default link' s:g1 s:g2
  endif
endfor
unlet s:g1 s:g2

" }}}2

" }}}1

" {{{1 Nested syntax

syntax region VimwikiPre start=/^\s*```\s*/ end=/```\s*$/ contains=@NoSpell
syntax match VimwikiPreStart /^\s*```\w\+/ contained contains=VimwikiPreStartName
syntax match VimwikiPreEnd /^\s*```\s*$/ contained
syntax match VimwikiPreStartName /\w\+/ contained

let s:ignored = {
      \ 'sh' : ['shCommandSub'] ,
      \ 'pandoc' : ['pandocDelimitedCodeBlock', 'pandocNoFormatted'] ,
      \}

for s:ft in map(
        \ filter(getline(1, '$'), 'v:val =~# ''^\s*```\w\+\s*$'''),
        \ 'matchstr(v:val, ''```\zs\w\+\ze\s*$'')')
  let s:cluster = '@VimwikiNested' . toupper(s:ft)
  let s:group = 'VimwikiPre' . toupper(s:ft)

  unlet b:current_syntax
  let s:iskeyword = &l:iskeyword
  let s:fdm = &l:foldmethod
  try
    execute 'syntax include' s:cluster 'syntax/' . s:ft . '.vim'
    execute 'syntax include' s:cluster 'after/syntax/' . s:ft . '.vim'
  catch
  endtry

  for s:ignore in get(s:ignored, s:ft, [])
    execute 'syntax cluster VimwikiNested' . toupper(s:ft) 'remove=' . s:ignore
  endfor

  let b:current_syntax='vimwiki'
  let &l:foldmethod = s:fdm
  let &iskeyword = s:iskeyword

  execute 'syntax region' s:group
        \ 'start=/^\s*```' . s:ft . '/ end=/```\s*$/'
        \ 'keepend transparent'
        \ 'contains=VimwikiPreStart,VimwikiPreEnd,@NoSpell,' . s:cluster
endfor

" }}}1

" {{{1 Highlighting

highlight default link time    number
highlight default link number  Constant
highlight default link version Statement

highlight default link VimwikiLinkUrl ModeMsg
highlight default link VimwikiLinkWiki Underlined
highlight default link VimwikiLinkMd Underlined
highlight default link VimwikiLinkRef Underlined
highlight default link VimwikiLinkRefTarget Underlined
highlight default      VimwikiLinkDate guifg=blue

highlight default link VimwikiEqIn Number

highlight default      VimwikiBold term=bold cterm=bold gui=bold
highlight default      VimwikiItalic term=italic cterm=italic gui=italic

highlight default link VimwikiCode PreProc

highlight default link VimwikiPre PreProc
highlight default link VimwikiPreStart VimwikiPre
highlight default link VimwikiPreEnd VimwikiPre
highlight default link VimwikiPreStartName Identifier

highlight default link VimwikiList Identifier
highlight default link VimwikiListTodo VimwikiList
highlight default link VimwikiListTodoDone Comment
highlight default link VimwikiLine Identifier

highlight default link VimwikiTodo Todo

highlight default link VimwikiQuote Comment

highlight default link VimwikiMarkers Normal
highlight default link VimwikiHeaderChar VimwikiMarkers
highlight default link VimwikiEqInChar VimwikiMarkers
highlight default link VimwikiCellSeparator VimwikiMarkers
highlight default link VimwikiBoldChar VimwikiMarkers
highlight default link VimwikiItalicChar VimwikiMarkers
highlight default link VimwikiCodeChar VimwikiMarkers
highlight default link VimwikiQuoteChar Todo

let s:color_guifg_light = [
      \ '#aa5858', '#507030', '#1030a0', '#103040', '#505050', '#636363']
let s:color_ctermfg_light = [
      \ 'DarkRed', 'DarkGreen', 'DarkBlue', 'Black', 'Black', 'Black']
let s:color_guifg_dark = [
      \ '#e08090', '#80e090', '#6090e0', '#c0c0f0', '#e0e0f0', '#f0f0f0']
let s:color_ctermfg_dark = [
      \ 'Red', 'Green', 'Blue', 'White', 'White', 'White']
for s:i in range(5)
  execute 'highlight default VimwikiHeader' . (s:i + 1)
        \ 'gui=bold term=bold cterm=bold'
        \ 'guifg='   . s:color_guifg_{&background}[s:i]
        \ 'ctermfg=' . s:color_ctermfg_{&background}[s:i]
endfor

" }}}1

" vim: fdm=marker sw=2
