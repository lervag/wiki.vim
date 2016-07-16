" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:current_syntax') | finish | endif
let b:current_syntax = 'vimwiki'

syntax spell toplevel
syntax sync minlines=100

" {{{1 Headers

for s:i in range(1,6)
  execute 'syntax match wikiHeader' . s:i
        \ . ' /^#\{' . s:i . '}\zs[^#].*/'
        \ . ' contains=@Spell,wikiHeaderChar,wikiTodo,@wikiLink'
endfor
syntax match wikiHeaderChar contained /^#\+/

let s:gcolors = {
      \ 'light' : ['#aa5858','#507030','#1030a0','#103040','#505050','#636363'],
      \ 'dark' : ['#e08090','#80e090','#6090e0','#c0c0f0','#e0e0f0','#f0f0f0']
      \}
let s:ccolors = {
      \ 'light' : ['DarkRed','DarkGreen','DarkBlue','Gray','DarkGray','Black'],
      \ 'dark' : ['Red','Green','Blue','Gray','LightGray','White']
      \}
for s:i in range(6)
  execute 'highlight default wikiHeader' . (s:i + 1)
        \ 'gui=bold term=bold cterm=bold'
        \ 'guifg='   . s:gcolors[&background][s:i]
        \ 'ctermfg=' . s:ccolors[&background][s:i]
endfor
unlet s:i s:gcolors s:ccolors

highlight default link wikiHeaderChar Normal

" }}}1
" {{{1 Links

" Add syntax groups and clusters for links
for [s:group, s:rx; s:contained] in [
      \ ['wikiLinkUrl',       'url',         'wikiLinkUrlConceal'],
      \ ['wikiLinkWiki',      'wiki',        'wikiLinkWikiConceal'],
      \ ['wikiLinkRef',       'ref_simple'],
      \ ['wikiLinkRefTarget', 'ref_target',  'wikiLinkUrl'],
      \ ['wikiLinkRef',       'ref',         'wikiLinkRefConceal'],
      \ ['wikiLinkMd',        'md',          'wikiLinkMdConceal'],
      \ ['wikiLinkDate',      'date'],
      \]
  execute 'syntax cluster wikiLink  add=' . s:group
  execute 'syntax match' s:group
        \ '/' . vimwiki#link#get_matcher_opt(s:rx, 'rx') . '/'
        \ 'display contains=@NoSpell'
        \ . (empty(s:contained) ? '' : ',' . join(s:contained, ','))

  call filter(s:contained, 'v:val !~# ''Conceal''')
  execute 'syntax match' s:group . 'T'
        \ '/' . vimwiki#link#get_matcher_opt(s:rx, 'rx') . '/'
        \ 'display contained contains=@NoSpell'
        \ . (empty(s:contained) ? '' : ',' . join(s:contained, ','))
endfor
unlet s:group s:rx s:contained

syntax match wikiLinkUrlConceal
      \ `\%(///\=[^/ \t]\+/\)\zs\S\+\ze\%([/#?]\w\|\S\{15}\)`
      \ cchar=~ contained transparent contains=NONE conceal
syntax match wikiLinkWikiConceal /\[\[\/\?\%([^\\\]]\{-}|\)\?/
      \ contained transparent contains=NONE conceal
syntax match wikiLinkWikiConceal /\]\]/
      \ contained transparent contains=NONE conceal
syntax match wikiLinkMdConceal /\[/
      \ contained transparent contains=NONE conceal
syntax match wikiLinkMdConceal /\]([^\\]\{-})/
      \ contained transparent contains=NONE conceal
syntax match wikiLinkRefConceal /[\]\[]\@<!\[/
      \ contained transparent contains=NONE conceal
syntax match wikiLinkRefConceal /\]\[[^\\\[\]]\{-}\]/
      \ contained transparent contains=NONE conceal

highlight default link wikiLinkUrl ModeMsg
highlight default link wikiLinkWiki Underlined
highlight default link wikiLinkMd Underlined
highlight default link wikiLinkRef Underlined
highlight default link wikiLinkRefTarget Underlined
highlight default      wikiLinkDate guifg=blue

" }}}1
" {{{1 Table

syntax match wikiTable /^\s*|.\+|\s*$/ transparent contains=@wikiInTable,@Spell
syntax match wikiTableSeparator /|/ contained
syntax match wikiTableLine /^\s*[|\-+:]\+\s*$/ contained

syntax match wikiTableFormula /^\/\* tmf:.*\*\//
      \ contains=wikiTableFormulaConcealed
syntax match wikiTableFormulaConcealed /\s*\%(\/\* tmf:\s*\|\*\/\)\s*/
      \ contained

for [s:group, s:target] in [
      \ ['wikiTableSeparator', ''],
      \ ['wikiTableLine', ''],
      \ ['wikiTodo', ''],
      \ ['wikiTime', ''],
      \ ['wikiNumber', ''],
      \ ['wikiBoldT', 'wikiBold'],
      \ ['wikiItalicT', 'wikiItalic'],
      \ ['wikiCodeT', 'wikiCode'],
      \ ['wikiEqInT', 'wikiEqIn'],
      \ ['wikiLinkUrlT', 'wikiLinkUrl'],
      \ ['wikiLinkWikiT', 'wikiLinkWiki'],
      \ ['wikiLinkRefT', 'wikiLinkRef'],
      \ ['wikiLinkRefTargetT', 'wikiLinkRefTarget'],
      \ ['wikiLinkRefT', 'wikiLinkRef'],
      \ ['wikiLinkMdT', 'wikiLinkMd'],
      \ ['wikiLinkDateT', 'wikiLinkDate'],
      \]
  execute 'syntax cluster wikiInTable add=' . s:group
  if !empty(s:target)
    execute 'highlight default link' s:group s:target
  endif
endfor

highlight default wikiTableSeparator ctermfg=lightgray guifg=#40474d
highlight default link wikiTableLine wikiTableSeparator
highlight default wikiTableFormula ctermfg=darkgray guifg=gray
highlight default wikiTableFormulaConcealed ctermfg=8 guifg=bg

" }}}1
" {{{1 Code and nested syntax

syntax match wikiCode /`[^`]\+`/ contains=wikiCodeConceal
syntax match wikiCodeConceal contained /`/ conceal
syntax match wikiCodeT /`[^`]\+`/ contained

syntax region wikiPre start=/^\s*```\s*/ end=/```\s*$/ contains=@NoSpell
syntax match wikiPreStart /^\s*```\w\+/ contained contains=wikiPreStartName
syntax match wikiPreEnd /^\s*```\s*$/ contained
syntax match wikiPreStartName /\w\+/ contained

let s:ignored = {
      \ 'sh' : ['shCommandSub'] ,
      \ 'pandoc' : ['pandocDelimitedCodeBlock', 'pandocNoFormatted'] ,
      \}

for s:ft in map(
        \ filter(getline(1, '$'), 'v:val =~# ''^\s*```\w\+\s*$'''),
        \ 'matchstr(v:val, ''```\zs\w\+\ze\s*$'')')
  let s:cluster = '@wikiNested' . toupper(s:ft)
  let s:group = 'wikiPre' . toupper(s:ft)

  unlet b:current_syntax
  let s:iskeyword = &l:iskeyword
  let s:fdm = &l:foldmethod
  try
    execute 'syntax include' s:cluster 'syntax/' . s:ft . '.vim'
    execute 'syntax include' s:cluster 'after/syntax/' . s:ft . '.vim'
  catch
  endtry

  for s:ignore in get(s:ignored, s:ft, [])
    execute 'syntax cluster wikiNested' . toupper(s:ft) 'remove=' . s:ignore
  endfor

  let b:current_syntax='vimwiki'
  let &l:foldmethod = s:fdm
  let &iskeyword = s:iskeyword

  execute 'syntax region' s:group
        \ 'start=/^\s*```' . s:ft . '/ end=/```\s*$/'
        \ 'keepend transparent'
        \ 'contains=wikiPreStart,wikiPreEnd,@NoSpell,' . s:cluster
endfor

highlight default link wikiCode PreProc
highlight default link wikiPre PreProc
highlight default link wikiPreStart wikiPre
highlight default link wikiPreEnd wikiPre
highlight default link wikiPreStartName Identifier

" }}}1
" {{{1 Lists

syntax match wikiList /^\s*[-*]\s\+/
syntax match wikiList /::\%(\s\|$\)/
syntax match wikiListTodo /^\s*[-*] \[ \]/
syntax match wikiListTodoDone /^\s*[-*] \[[xX]\]/ contains=@wikiLink,@Spell

highlight default link wikiList Identifier
highlight default link wikiListTodo wikiList
highlight default link wikiListTodoDone Comment

" }}}1
" {{{1 Formatting

execute 'syntax match wikiBold'
      \ '/' . vimwiki#rx#bold() . '/'
      \ 'contains=wikiBoldConceal,@Spell'
execute 'syntax match wikiBoldT'
      \ '/' . vimwiki#rx#bold() . '/'
      \ 'contained contains=@Spell'
syntax match wikiBoldConceal /*/ contained conceal

execute 'syntax match wikiItalic'
      \ '/' . vimwiki#rx#italic() . '/'
      \ 'contains=wikiItalicConceal,@Spell'
execute 'syntax match wikiItalicT'
      \ '/' . vimwiki#rx#italic() . '/'
      \ 'contained contains=@Spell'
syntax match wikiItalicConceal /_/ contained conceal

highlight default wikiBold term=bold cterm=bold gui=bold
highlight default wikiItalic term=italic cterm=italic gui=italic

" }}}1
" {{{1 Math

syntax match wikiEq  /\$[^$`]\+\$/ contains=wikiEqConceal
syntax match wikiEqT /\$[^$`]\+\$/ contained
syntax match wikiEqConceal /\$/ contained conceal

highlight default link wikiEqIn Number

" }}}1
" {{{1 Miscellaneous

execute 'syntax match wikiTodo /' . vimwiki#rx#todo() . '/'
highlight default link wikiTodo Todo

syntax region wikiQuote start=/^>\s\+/ end=/^$/ contains=wikiQuoteChar
syntax match wikiQuoteChar contained /^>/ conceal cchar= 
highlight default link wikiQuoteChar Todo
highlight default link wikiQuote Comment

syntax match wikiNumber  /\d\+\.\d\+/
syntax match wikiVersion /\d\+\.\d\+\(\.\d\)\+/
syntax match wikiTime    /\d\d:\d\d/
syntax match wikiLine    /^\s*-\{4,}\s*$/
highlight default link wikiNumber  Constant
highlight default link wikiVersion Statement
highlight default link wikiTime    Number
highlight default link wikiLine Identifier

" }}}1

" vim: fdm=marker sw=2
