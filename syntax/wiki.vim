" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

if exists('b:current_syntax') | finish | endif
let b:current_syntax = 'wiki'

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

highlight default link wikiHeaderChar Normal

unlet s:i s:gcolors s:ccolors

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
        \ '/' . wiki#link#get_matcher_opt(s:rx, 'rx') . '/'
        \ 'display contains=@NoSpell'
        \ . (empty(s:contained) ? '' : ',' . join(s:contained, ','))

  call filter(s:contained, 'v:val !~# ''Conceal''')
  execute 'syntax match' s:group . 'T'
        \ '/' . wiki#link#get_matcher_opt(s:rx, 'rx') . '/'
        \ 'display contained contains=@NoSpell'
        \ . (empty(s:contained) ? '' : ',' . join(s:contained, ','))
endfor

syntax match wikiLinkUrlConceal
      \ `\%(///\=[^/ \t]\+/\)\zs\S\+\ze\%([/#?]\w\|\S\{15}\)`
      \ cchar=~ contained transparent contains=NONE conceal
syntax match wikiLinkWikiConceal /\[\[\%(\/\|#\)\?\%([^\\\]]\{-}|\)\?/
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
highlight default link wikiLinkDate MoreMsg

unlet s:group s:rx s:contained

" }}}1
" {{{1 Table

syntax match wikiTable /^\s*|.\+|\s*$/ transparent contains=@wikiInTable,@Spell
syntax match wikiTableSeparator /|/ contained
syntax match wikiTableLine /^\s*[|\-+:]\+\s*$/ contained

syntax match wikiTableFormulaLine /^\s*\/\/ tmf:.*/ contains=wikiTableFormula
syntax match wikiTableFormula /^\s*\/\/ tmf:\zs.*/ contained
      \ contains=wikiTableFormulaChars,wikiTableFormulaSyms
syntax match wikiTableFormulaSyms /[$=():]/ contained
syntax match wikiTableFormulaChars /\a\|,/ contained

for [s:group, s:target] in [
      \ ['wikiTableSeparator', ''],
      \ ['wikiTableLine', ''],
      \ ['wikiTodo', ''],
      \ ['wikiTime', ''],
      \ ['wikiNumber', ''],
      \ ['wikiBoldT', 'wikiBold'],
      \ ['wikiItalicT', 'wikiItalic'],
      \ ['wikiCodeT', 'wikiCode'],
      \ ['wikiEqT', 'WikiEq'],
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

highlight default wikiTableSeparator ctermfg=black guifg=#40474d
highlight default link wikiTableLine wikiTableSeparator
highlight default link wikiTableFormulaLine wikiTableSeparator
highlight default link wikiTableFormula Number
highlight default link wikiTableFormulaSyms Special
highlight default link wikiTableFormulaChars ModeMsg
" highlight default wikiTableFormulaLine ctermfg=darkgray guifg=gray
" highlight default wikiTableFormula ctermfg=8 guifg=bg

unlet s:group s:target

" }}}1
" {{{1 Code and nested syntax

syntax match wikiCode /`[^`]\+`/ contains=wikiCodeConceal,@NoSpell
syntax match wikiCodeConceal contained /`/ conceal
syntax match wikiCodeT /`[^`]\+`/ contained

syntax region wikiPre start=/^\s*```\s*/ end=/```\s*$/ contains=@NoSpell
syntax match wikiPreStart /^\s*```\w\+/ contained contains=wikiPreStartName
syntax match wikiPreEnd /^\s*```\s*$/ contained
syntax match wikiPreStartName /\w\+/ contained

let s:ignored = {
      \ 'sh' : ['shCommandSub'],
      \ 'pandoc' : ['pandocDelimitedCodeBlock', 'pandocNoFormatted'],
      \ 'ruby' : ['rubyString'],
      \ 'make' : ['makeBString', 'makeIdent'],
      \ 'resolv' : ['resolvError'],
      \ 'python' : ['pythonFString'],
      \ 'tex' : ['texString'],
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

  let b:current_syntax = 'wiki'
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

unlet s:ignored

" }}}1
" {{{1 Lists

syntax match wikiList /^\s*[-*]\s\+/
syntax match wikiList /::\%(\s\|$\)/
syntax match wikiListTodo /^\s*[-*] \[ \]/ contains=wikiList
syntax match wikiListTodoPartial /^\s*[-*] \[[.o]\]/ contains=wikiList
syntax match wikiListTodoDone /^\s*[-*] \[[xX]\]/ contains=wikiList

highlight default link wikiList Identifier
highlight default link wikiListTodo Comment
highlight default link wikiListTodoDone Comment
highlight default link wikiListTodoPartial Comment
highlight wikiListTodo cterm=bold gui=bold
highlight wikiListTodoPartial cterm=none gui=none

" }}}1
" {{{1 Formatting

execute 'syntax match wikiBold'
      \ '/' . wiki#rx#bold() . '/'
      \ 'contains=wikiBoldConceal,@Spell'
execute 'syntax match wikiBoldT'
      \ '/' . wiki#rx#bold() . '/'
      \ 'contained contains=@Spell'
syntax match wikiBoldConceal /*/ contained conceal

execute 'syntax match wikiItalic'
      \ '/' . wiki#rx#italic() . '/'
      \ 'contains=wikiItalicConceal,@Spell'
execute 'syntax match wikiItalicT'
      \ '/' . wiki#rx#italic() . '/'
      \ 'contained contains=@Spell'
syntax match wikiItalicConceal /_/ contained conceal

highlight default wikiBold term=bold cterm=bold ctermfg=black gui=bold
highlight default wikiItalic term=italic cterm=italic gui=italic

" }}}1
" {{{1 Math

syntax match wikiEq  /\$[^$`]\+\$/ contains=wikiEqConceal
syntax match wikiEqT /\$[^$`]\+\$/ contained
syntax match wikiEqConceal /\$/ contained conceal

highlight default link WikiEq Number

" }}}1
" {{{1 Miscellaneous

execute 'syntax match wikiTodo /' . wiki#rx#todo() . '/'
highlight default link wikiTodo Todo

execute 'syntax match wikiDone /' . wiki#rx#done() . '/'
highlight default link wikiDone Statement

syntax region wikiQuote start=/^>\s\+/ end=/^$/ contains=wikiQuoteChar
syntax match wikiQuoteChar contained /^>/
highlight default link wikiQuoteChar Comment
highlight default link wikiQuote Conceal

syntax match wikiNumber  /\d\+\.\d\+/
syntax match wikiIPNum   /\d\+\(\.\d\+\)\{3}/
syntax match wikiVersion /v\d\+\(\.\d\+\)*/
syntax match wikiVersion /\(version\|versjon\) \zs\d\+\(\.\d\+\)*/
syntax match wikiTime    /\d\d:\d\d/
syntax match wikiLine    /^\s*-\{4,}\s*$/
highlight default link wikiNumber  Constant
highlight default link wikiIPNum   Identifier
highlight default link wikiVersion Statement
highlight default link wikiTime    Number
highlight default link wikiLine Identifier

" }}}1
