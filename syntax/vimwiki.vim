" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:current_syntax') | finish | endif
let b:current_syntax = "vimwiki"

syntax spell toplevel
syntax sync minlines=100

"
" Match links
"
for s:m in values(g:vimwiki.link_matcher)
  execute 'syntax cluster VimwikiLink  add=' . s:m.syntax
  execute 'syntax cluster VimwikiLinkT add=' . s:m.syntax . 'T'
  execute 'syntax match ' . s:m.syntax . ' `' . s:m.rx_full . '` '
        \ . 'display contains=@NoSpell,' . s:m.syntax . 'Char'
  execute 'syntax match ' . s:m.syntax . 'T `' . s:m.rx_full . '` '
        \ . 'display contained'
endfor

"
" Standard syntax elements
"
syntax match line    /-\{10,}/
syntax match number  /\d\+\.\d\+/
syntax match version /\d\+\.\d\+\(\.\d\)\+/
syntax match time    /\d\d:\d\d/
syntax match date    /\d\d\d\d-\d\d-\d\d/

" {{{1 Concealed

" Conceal some contained characters
syntax match VimwikiEqInChar       contained /\$/   conceal
syntax match VimwikiBoldChar       contained /*/    conceal
syntax match VimwikiItalicChar     contained /_/    conceal
syntax match VimwikiBoldItalicChar contained /\*_/  conceal
syntax match VimwikiItalicBoldChar contained /_\*/  conceal
syntax match VimwikiCodeChar       contained /`/    conceal
syntax match VimwikiSuperScript    contained /^/    conceal
syntax match VimwikiSubScript      contained /,,/   conceal

" Match groups to force visible
syntax match VimwikiEqInCharT       contained /\$/
syntax match VimwikiBoldCharT       contained /*/
syntax match VimwikiItalicCharT     contained /_/
syntax match VimwikiBoldItalicCharT contained /\*_/
syntax match VimwikiItalicBoldCharT contained /_\*/
syntax match VimwikiCodeCharT       contained /`/
syntax match VimwikiSuperScriptT    contained /^/
syntax match VimwikiSubScriptT      contained /,,/

" Shorten long URLS (conceal middle part)
syntax match VimwikiLinkUrlChar
      \ `\%(///\=[^/ \t]\+/\)\zs\S\+\ze\%([/#?]\w\|\S\{15}\)`
      \ cchar=~ contained transparent contains=NONE conceal

syntax match VimwikiLinkWikiChar /\[\[\/\?\%([^\\\]]\{-}|\)\?/
      \ contained transparent contains=NONE conceal
syntax match VimwikiLinkWikiChar /\]\]/
      \ contained transparent contains=NONE conceal

syntax match VimwikiLinkRefChar /[\]\[]\@<!\[/
      \ contained transparent contains=NONE conceal
syntax match VimwikiLinkRefChar /\][\]\[]\@!/
      \ contained transparent contains=NONE conceal
" syntax match VimwikiLinkRefChar /...\][\]\[]\@!/
"       \ contained transparent contains=NONE conceal
syntax match VimwikiLinkMdChar /\[/
      \ contained transparent contains=NONE conceal
syntax match VimwikiLinkMdChar /\]([^\\]\{-})/
      \ contained transparent contains=NONE conceal

" }}}1

" {{{1 Define main syntax groups

" Header
for s:i in range(1,6)
  execute 'syntax match VimwikiHeader' . s:i
        \ . ' /^#\{' . s:i . '}\zs[^#].*/'
        \ . ' contains=VimwikiTodo,VimwikiHeaderChar,'
        \ .           'VimwikiCode,@VimwikiLink,@Spell'
endfor
syntax match VimwikiHeaderChar contained /^#\+/

" TODO like items
execute 'syntax match VimwikiTodo /' . g:vimwiki.rx.todo . '/'

" Tables
syntax match VimwikiTableRow /^\s*|.\+|\s*$/
      \ transparent contains=VimwikiCellSeparator,
                           \ VimwikiLinkT,
                           \ VimwikiLinkMdT,
                           \ VimwikiLinkRefT,
                           \ VimwikiNoExistsLinkT,
                           \ VimwikiTodo,
                           \ VimwikiBoldT,
                           \ VimwikiItalicT,
                           \ VimwikiBoldItalicT,
                           \ VimwikiItalicBoldT,
                           \ VimwikiSuperScriptT,
                           \ VimwikiSubScriptT,
                           \ VimwikiCodeT,
                           \ VimwikiEqInT,
                           \ @Spell
syntax match VimwikiCellSeparator
      \ /\%(|\)\|\%(-\@<=+\-\@=\)\|\%([|+]\@<=-\+\)/ contained

" Lists
syntax match VimwikiList /^\s*[-*#]/
syntax match VimwikiList /::\%(\s\|$\)/
syntax match VimwikiListTodo /^\s*[-*#] \[ \]/
syntax match VimwikiListTodo /^\s*[-*#] \[ \]/
syntax match VimwikiListTodoDone /^\s*[-*#] \[[xX]\]/
      \ contains=@VimwikiLink,@Spell

syntax match VimwikiEqIn  /\$[^$`]\+\$/ contains=VimwikiEqInChar
syntax match VimwikiEqInT /\$[^$`]\+\$/ contained contains=VimwikiEqInCharT

execute 'syntax match VimwikiBold /'.g:vimwiki.rx.bold.'/ contains=VimwikiBoldChar,@Spell'
execute 'syntax match VimwikiBoldT /'.g:vimwiki.rx.bold.'/ contained contains=VimwikiBoldCharT,@Spell'

execute 'syntax match VimwikiItalic /'.g:vimwiki.rx.italic.'/ contains=VimwikiItalicChar,@Spell'
execute 'syntax match VimwikiItalicT /'.g:vimwiki.rx.italic.'/ contained contains=VimwikiItalicCharT,@Spell'

execute 'syntax match VimwikiBoldItalic /'.g:vimwiki.rx.boldItalic.'/ contains=VimwikiBoldItalicChar,VimwikiItalicBoldChar,@Spell'
execute 'syntax match VimwikiBoldItalicT /'.g:vimwiki.rx.boldItalic.'/ contained contains=VimwikiBoldItalicChatT,VimwikiItalicBoldCharT,@Spell'

execute 'syntax match VimwikiItalicBold /'.g:vimwiki.rx.italicBold.'/ contains=VimwikiBoldItalicChar,VimwikiItalicBoldChar,@Spell'
execute 'syntax match VimwikiItalicBoldT /'.g:vimwiki.rx.italicBold.'/ contained contains=VimwikiBoldItalicCharT,VimsikiItalicBoldCharT,@Spell'

execute 'syntax match VimwikiSuperScript /'.g:vimwiki.rx.superScript.'/ contains=VimwikiSuperScriptChar,@Spell'
execute 'syntax match VimwikiSuperScriptT /'.g:vimwiki.rx.superScript.'/ contained contains=VimwikiSuperScriptCharT,@Spell'

execute 'syntax match VimwikiSubScript /'.g:vimwiki.rx.subScript.'/ contains=VimwikiSubScriptChar,@Spell'
execute 'syntax match VimwikiSubScriptT /'.g:vimwiki.rx.subScript.'/ contained contains=VimwikiSubScriptCharT,@Spell'

syntax match VimwikiCode /`[^`]\+`/ contains=VimwikiCodeChar
syntax match VimwikiCodeT /`[^`]\+`/ contained contains=VimwikiCodeCharT

syntax match VimwikiHR /^\s*-\{4,}\s*$/

" }}}

" {{{1 Nested syntax

syntax region VimwikiPre start=/^\s*```\s*/ end=/```\s*$/ contains=@NoSpell
syntax match VimwikiPreStart /^\s*```\w\+/ contained contains=VimwikiPreStartName
syntax match VimwikiPreEnd /^\s*```\s*$/ contained
syntax match VimwikiPreStartName /\w\+/ contained

let s:ignored = {
      \ 'sh' : ['shCommandSub'] ,
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

" {{{1 Define highlighting

" Set colors
hi def  date    guifg=blue
hi def  line    guifg=black
hi link line    line
hi link time    number
hi link number  Constant
hi link version Statement

hi def link VimwikiMarkers Normal

hi def link VimwikiEqIn Number
hi def link VimwikiEqInT VimwikiEqIn

hi def VimwikiBold term=bold cterm=bold gui=bold
hi def link VimwikiBoldT VimwikiBold

hi def VimwikiItalic term=italic cterm=italic gui=italic
hi def link VimwikiItalicT VimwikiItalic

hi def VimwikiBoldItalic term=bold cterm=bold gui=bold,italic
hi def link VimwikiItalicBold VimwikiBoldItalic
hi def link VimwikiBoldItalicT VimwikiBoldItalic
hi def link VimwikiItalicBoldT VimwikiBoldItalic

hi def VimwikiUnderline gui=underline

hi def link VimwikiCode PreProc
hi def link VimwikiCodeT VimwikiCode

hi def link VimwikiPre PreProc
hi def link VimwikiPreT VimwikiPre
hi def link VimwikiPreStart VimwikiPre
hi def link VimwikiPreEnd VimwikiPre
hi def link VimwikiPreStartName Identifier

hi def link VimwikiMath Number
hi def link VimwikiMathT VimwikiMath

hi def link VimwikiList Identifier
hi def link VimwikiListTodo VimwikiList
hi def link VimwikiListTodoDone Comment
hi def link VimwikiHR Identifier
hi def link VimwikiTag Keyword

hi def link VimwikiSuperScript Number
hi def link VimwikiSuperScriptT VimwikiSuperScript

hi def link VimwikiSubScript Number
hi def link VimwikiSubScriptT VimwikiSubScript

hi def link VimwikiTodo Todo
hi def link VimwikiComment Comment

hi def link VimwikiPlaceholder SpecialKey
hi def link VimwikiPlaceholderParam String
hi def link VimwikiHTMLtag SpecialKey

hi def link VimwikiEqInChar VimwikiMarkers
hi def link VimwikiCellSeparator VimwikiMarkers
hi def link VimwikiBoldChar VimwikiMarkers
hi def link VimwikiItalicChar VimwikiMarkers
hi def link VimwikiBoldItalicChar VimwikiMarkers
hi def link VimwikiItalicBoldChar VimwikiMarkers
hi def link VimwikiSuperScriptChar VimwikiMarkers
hi def link VimwikiSubScriptChar VimwikiMarkers
hi def link VimwikiCodeChar VimwikiMarkers
hi def link VimwikiHeaderChar VimwikiMarkers

hi def link VimwikiLinkUrl ModeMsg
hi def link VimwikiLinkWiki Underlined
hi def link VimwikiLinkMd Underlined
hi def link VimwikiLinkRef Underlined
hi def link VimwikiLinkRefTarget Underlined

"
" Table
"
hi def link VimwikiEqInCharT VimwikiMarkers
hi def link VimwikiBoldCharT VimwikiMarkers
hi def link VimwikiItalicCharT VimwikiMarkers
hi def link VimwikiBoldItalicCharT VimwikiMarkers
hi def link VimwikiItalicBoldCharT VimwikiMarkers
hi def link VimwikiSuperScriptCharT VimwikiMarkers
hi def link VimwikiSubScriptCharT VimwikiMarkers
hi def link VimwikiCodeCharT VimwikiMarkers
hi def link VimwikiHeaderCharT VimwikiMarkers
hi def link VimwikiLinkCharT VimwikiLinkT
hi def link VimwikiNoExistsLinkCharT VimwikiNoExistsLinkT
hi def link VimwikiLinkUrlT VimwikiLinkUrl
hi def link VimwikiLinkWikiT VimwikiLinkWiki
hi def link VimwikiLinkMdT VimwikiLinkMd
hi def link VimwikiLinkRefT VimwikiLinkRef
hi def link VimwikiLinkRefTargetT VimwikiLinkRefTarget

"
" Header groups highlighting
"
let g:vimwiki_hcolor_guifg_light = ['#aa5858','#507030','#1030a0','#103040','#505050','#636363']
let g:vimwiki_hcolor_ctermfg_light = ['DarkRed','DarkGreen','DarkBlue','Black','Black','Black']
let g:vimwiki_hcolor_guifg_dark = ['#e08090','#80e090','#6090e0','#c0c0f0','#e0e0f0','#f0f0f0']
let g:vimwiki_hcolor_ctermfg_dark = ['Red','Green','Blue','White','White','White']
for s:i in range(1,6)
  execute 'hi def VimwikiHeader'.s:i.' guibg=bg guifg='.g:vimwiki_hcolor_guifg_{&bg}[s:i-1].' gui=bold ctermfg='.g:vimwiki_hcolor_ctermfg_{&bg}[s:i-1].' term=bold cterm=bold'
endfor

" }}}1

" vim: fdm=marker sw=2
