" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:current_syntax') | finish | endif
let b:current_syntax = "vimwiki"

syntax spell toplevel
let s:options = ' contained transparent contains=NONE conceal'

function! s:add_target_syntax(target, type) " {{{
  let prefix0 = 'syntax match '.a:type.' `'
  let suffix0 = '` display contains=@NoSpell,VimwikiLinkRest,'.a:type.'Char'
  let prefix1 = 'syntax match '.a:type.'T `'
  let suffix1 = '` display contained'
  execute prefix0. a:target. suffix0
  execute prefix1. a:target. suffix1
endfunction

" }}}
function! s:wrap_wikilink1_rx(target) " {{{
  return '[\]\[]\@<!' . a:target . '[\]\[]\@!'
endfunction

" }}}
function! s:existing_mkd_refs() " {{{
  call vimwiki#markdown_base#reset_mkd_refs()
  return keys(vimwiki#markdown_base#get_reflinks())
endfunction

" }}}
function! s:apply_template(template, rxUrl, rxDesc) " {{{1
  let l:lnk = a:template

  if !empty(a:rxUrl)
    let l:lnk = substitute(l:lnk, '__LinkUrl__',
          \ '\=''' . a:rxUrl . '''', 'g')
  endif

  if !empty(a:rxDesc)
    let l:lnk = substitute(l:lnk, '__LinkDescription__',
          \ '\=''' . a:rxDesc . '''', 'g')
  endif

  return l:lnk
endfunction

" }}}1
function! s:detect_nested() " {{{1
  let last_word = '\v.*<(\w+)\s*$'
  let lines = map(filter(getline(1, "$"), 'v:val =~ "```" && v:val =~ last_word'),
        \ 'substitute(v:val, last_word, "\\=submatch(1)", "")')
  let dict = {}
  for elem in lines
    let dict[elem] = elem
  endfor
  return dict
endfunction

" }}}1
function! s:add_nested(filetype, start, end, textSnipHl) abort " {{{1
  " From http://vim.wikia.com/wiki/VimTip857
  let ft=toupper(a:filetype)
  let group='textGroup'.ft
  if exists('b:current_syntax')
    let s:current_syntax=b:current_syntax
    " Remove current syntax definition, as some syntax files (e.g. cpp.vim)
    " do nothing if b:current_syntax is defined.
    unlet b:current_syntax
  endif

  " Some syntax files set up iskeyword which might scratch vimwiki a bit.
  " Let us save and restore it later.
  " let b:skip_set_iskeyword = 1
  let is_keyword = &iskeyword

  try
    " keep going even if syntax file is not found
    execute 'syntax include @'.group.' syntax/'.a:filetype.'.vim'
    execute 'syntax include @'.group.' after/syntax/'.a:filetype.'.vim'
  catch
  endtry

  let &iskeyword = is_keyword

  if exists('s:current_syntax')
    let b:current_syntax=s:current_syntax
  else
    unlet b:current_syntax
  endif
  execute 'syntax region textSnip'.ft.
        \ ' matchgroup='.a:textSnipHl.
        \ ' start="'.a:start.'" end="'.a:end.'"'.
        \ ' contains=@'.group.' keepend'

  " A workaround to Issue 115: Nested Perl syntax highlighting differs from
  " regular one.
  " Perl syntax file has perlFunctionName which is usually has no effect due to
  " 'contained' flag. Now we have 'syntax include' that makes all the groups
  " included as 'contained' into specific group.
  " Here perlFunctionName (with quite an angry regexp "\h\w*[^:]") clashes with
  " the rest syntax rules as now it has effect being really 'contained'.
  " Clear it!
  if ft =~? 'perl'
    syntax clear perlFunctionName
  endif
endfunction

" }}}1

" {{{1 Match links

call s:add_target_syntax(g:vimwiki.rx.link_wiki, 'VimwikiLink')
call s:add_target_syntax(g:vimwiki.rx.link_wiki1, 'VimwikiWikiLink1')
call s:add_target_syntax(g:vimwiki.rx.link_web, 'VimwikiLink')
call s:add_target_syntax(g:vimwiki.rx.link_web1, 'VimwikiWeblink1')

" WikiLink
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\w\+:'

" [[nonwiki-scheme-URL]]
let s:target = s:apply_template(
      \ vimwiki#u#escape(g:vimwiki.templ.link_wiki0_1),
      \ s:rxSchemes.g:vimwiki.rx.link_wiki_url, g:vimwiki.rx.link_wiki_text)
call s:add_target_syntax(s:target, 'VimwikiLink')

" [[nonwiki-scheme-URL|DESCRIPTION]]
let s:target = s:apply_template(
      \ vimwiki#u#escape(g:vimwiki.templ.link_wiki0_2),
      \ s:rxSchemes.g:vimwiki.rx.link_wiki_url, g:vimwiki.rx.link_wiki_text)
call s:add_target_syntax(s:target, 'VimwikiLink')

" [nonwiki-scheme-URL]
let s:target = s:apply_template(
      \ vimwiki#u#escape(g:vimwiki.templ.link_wiki1_1),
      \ s:rxSchemes.'[^\\\[\]]\{-}', '[^\\\[\]]\{-}')
call s:add_target_syntax(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')

" [DESCRIPTION][nonwiki-scheme-URL]
let s:target = s:apply_template(
      \ vimwiki#u#escape(g:vimwiki.templ.link_wiki1_2),
      \ s:rxSchemes.'[^\\\[\]]\{-}', '[^\\\[\]]\{-}')
call s:add_target_syntax(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')

" }}}1

" {{{1 Concealed

" Conceal some contained characters
syntax match VimwikiEqInChar       contained /\$/   conceal
syntax match VimwikiBoldChar       contained /*/    conceal
syntax match VimwikiItalicChar     contained /_/    conceal
syntax match VimwikiBoldItalicChar contained /\*_/  conceal
syntax match VimwikiItalicBoldChar contained /_\*/  conceal
syntax match VimwikiCodeChar       contained /`/    conceal
syntax match VimwikiDelTextChar    contained /\~\~/ conceal
syntax match VimwikiSuperScript    contained /^/    conceal
syntax match VimwikiSubScript      contained /,,/   conceal

" Match groups to force visible
syntax match VimwikiEqInCharT       contained /\$/
syntax match VimwikiBoldCharT       contained /*/
syntax match VimwikiItalicCharT     contained /_/
syntax match VimwikiBoldItalicCharT contained /\*_/
syntax match VimwikiItalicBoldCharT contained /_\*/
syntax match VimwikiCodeCharT       contained /`/
syntax match VimwikiDelTextCharT    contained /\~\~/
syntax match VimwikiSuperScriptT    contained /^/
syntax match VimwikiSubScriptT      contained /,,/

" Shorten long URLS (conceal middle part)
execute 'syntax match VimwikiLinkRest `\%(///\=[^/ \t]\+/\)\zs\S\+\ze'
      \ . '\%([/#?]\w\|\S\{15}\)` cchar=~' . s:options

execute 'syntax match VimwikiLinkChar /\[\[\/\?\%([^\\\]]\{-}|\)\?/' . s:options
execute 'syntax match VimwikiLinkChar /\]\]/' . s:options

execute 'syntax match VimwikiWikiLink1Char /[\]\[]\@<!\[/' . s:options
execute 'syntax match VimwikiWikiLink1Char /\][\]\[]\@!/' . s:options
"execute 'syntax match VimwikiWikiLink1Char /...\][\]\[]\@!/' . s:options
execute 'syntax match VimwikiWeblink1Char /\[/' . s:options
execute 'syntax match VimwikiWeblink1Char /\]([^\\]\{-})/' . s:options

" }}}1

" {{{1 Define main syntax groups

" Header
for s:i in range(1,6)
  execute 'syntax match VimwikiHeader' . s:i
        \ . ' /^#\{' . s:i . '}\zs[^#].*/'
        \ . ' contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,'
        \ .           'VimwikiCode,VimwikiLink,VimwikiWeblink1,'
        \ .           'VimwikiWikiLink1,@Spell'
endfor
syntax match VimwikiHeaderChar contained /^#\+/

" TODO like items
execute 'syntax match VimwikiTodo /' . g:vimwiki.rx.todo . '/'

" Tables
syntax match VimwikiTableRow /^\s*|.\+|\s*$/
      \ transparent contains=VimwikiCellSeparator,
                           \ VimwikiLinkT,
                           \ VimwikiWeblink1T,
                           \ VimwikiWikiLink1T,
                           \ VimwikiNoExistsLinkT,
                           \ VimwikiTodo,
                           \ VimwikiBoldT,
                           \ VimwikiItalicT,
                           \ VimwikiBoldItalicT,
                           \ VimwikiItalicBoldT,
                           \ VimwikiDelTextT,
                           \ VimwikiSuperScriptT,
                           \ VimwikiSubScriptT,
                           \ VimwikiCodeT,
                           \ VimwikiEqInT,
                           \ @Spell
syntax match VimwikiCellSeparator
      \ /\%(|\)\|\%(-\@<=+\-\@=\)\|\%([|+]\@<=-\+\)/ contained

" Lists
execute 'syntax match VimwikiList /'.g:vimwiki.rx.lst_item_no_checkbox.'/'
execute 'syntax match VimwikiList /'.g:vimwiki.rx.listDefine.'/'
execute 'syntax match VimwikiListTodo /'.g:vimwiki.rx.lst_item.'/'
execute 'syntax match VimwikiCheckBoxDone /'.g:vimwiki.rx.lst_item_no_checkbox.'\s*\['.g:vimwiki_listsyms_list[4].'\]\s.*$/ '.
      \ 'contains=VimwikiNoExistsLink,VimwikiLink,@Spell'

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

execute 'syntax match VimwikiDelText /'.g:vimwiki.rx.delText.'/ contains=VimwikiDelTextChar,@Spell'
execute 'syntax match VimwikiDelTextT /'.g:vimwiki.rx.delText.'/ contained contains=VimwikiDelTextChar,@Spell'

execute 'syntax match VimwikiSuperScript /'.g:vimwiki.rx.superScript.'/ contains=VimwikiSuperScriptChar,@Spell'
execute 'syntax match VimwikiSuperScriptT /'.g:vimwiki.rx.superScript.'/ contained contains=VimwikiSuperScriptCharT,@Spell'

execute 'syntax match VimwikiSubScript /'.g:vimwiki.rx.subScript.'/ contains=VimwikiSubScriptChar,@Spell'
execute 'syntax match VimwikiSubScriptT /'.g:vimwiki.rx.subScript.'/ contained contains=VimwikiSubScriptCharT,@Spell'

execute 'syntax match VimwikiCode /'.g:vimwiki.rx.code.'/ contains=VimwikiCodeChar'
execute 'syntax match VimwikiCodeT /'.g:vimwiki.rx.code.'/ contained contains=VimwikiCodeCharT'

" <hr> horizontal rule
execute 'syntax match VimwikiHR /'.g:vimwiki.rx.HR.'/'

execute 'syntax region VimwikiPre start=/'.g:vimwiki.rx.preStart.
      \ '/ end=/'.g:vimwiki.rx.preEnd.'/ contains=@Spell'

execute 'syntax region VimwikiMath start=/'.g:vimwiki.rx.mathStart.
      \ '/ end=/'.g:vimwiki.rx.mathEnd.'/ contains=@Spell'

" }}}

" {{{1 Define highlighting

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

hi def link VimwikiMath Number
hi def link VimwikiMathT VimwikiMath

hi def link VimwikiNoExistsLink SpellBad
hi def link VimwikiNoExistsLinkT VimwikiNoExistsLink

hi def link VimwikiLink Underlined
hi def link VimwikiLinkT VimwikiLink

hi def link VimwikiList Identifier
hi def link VimwikiListTodo VimwikiList
hi def link VimwikiCheckBoxDone Comment
hi def link VimwikiHR Identifier
hi def link VimwikiTag Keyword

hi def link VimwikiDelText Constant
hi def link VimwikiDelTextT VimwikiDelText

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
hi def link VimwikiDelTextChar VimwikiMarkers
hi def link VimwikiSuperScriptChar VimwikiMarkers
hi def link VimwikiSubScriptChar VimwikiMarkers
hi def link VimwikiCodeChar VimwikiMarkers
hi def link VimwikiHeaderChar VimwikiMarkers

hi def link VimwikiEqInCharT VimwikiMarkers
hi def link VimwikiBoldCharT VimwikiMarkers
hi def link VimwikiItalicCharT VimwikiMarkers
hi def link VimwikiBoldItalicCharT VimwikiMarkers
hi def link VimwikiItalicBoldCharT VimwikiMarkers
hi def link VimwikiDelTextCharT VimwikiMarkers
hi def link VimwikiSuperScriptCharT VimwikiMarkers
hi def link VimwikiSubScriptCharT VimwikiMarkers
hi def link VimwikiCodeCharT VimwikiMarkers
hi def link VimwikiHeaderCharT VimwikiMarkers
hi def link VimwikiLinkCharT VimwikiLinkT
hi def link VimwikiNoExistsLinkCharT VimwikiNoExistsLinkT

hi def link VimwikiWeblink1 VimwikiLink
hi def link VimwikiWeblink1T VimwikiLink

hi def link VimwikiWikiLink1 VimwikiLink
hi def link VimwikiWikiLink1T VimwikiLink

"
" header groups highlighting
"
let g:vimwiki_hcolor_guifg_light = ['#aa5858','#507030','#1030a0','#103040','#505050','#636363']
let g:vimwiki_hcolor_ctermfg_light = ['DarkRed','DarkGreen','DarkBlue','Black','Black','Black']
let g:vimwiki_hcolor_guifg_dark = ['#e08090','#80e090','#6090e0','#c0c0f0','#e0e0f0','#f0f0f0']
let g:vimwiki_hcolor_ctermfg_dark = ['Red','Green','Blue','White','White','White']
for s:i in range(1,6)
  execute 'hi def VimwikiHeader'.s:i.' guibg=bg guifg='.g:vimwiki_hcolor_guifg_{&bg}[s:i-1].' gui=bold ctermfg='.g:vimwiki_hcolor_ctermfg_{&bg}[s:i-1].' term=bold cterm=bold'
endfor

" }}}1

" {{{1 Nested syntax
for [s:hl_syntax, s:vim_syntax] in items(s:detect_nested())
  call s:add_nested(s:vim_syntax,
        \ g:vimwiki.rx.preStart.'\%(.*[[:blank:][:punct:]]\)\?'.
        \ s:hl_syntax.'\%([[:blank:][:punct:]].*\)\?',
        \ g:vimwiki.rx.preEnd, 'VimwikiPre')
endfor

" }}}1

" Standard syntax elements
syn match line    /-\{10,}/
syn match number  /\d\+\.\d\+/
syn match version /\d\+\.\d\+\(\.\d\)\+/
syn match time    /\d\d:\d\d/
syn match date    /\d\d\d\d-\d\d-\d\d/

" Set colors
hi def  date    guifg=blue
hi def  line    guifg=black
hi link line    line
hi link time    number
hi link number  Constant
hi link version Statement

" vim: fdm=marker sw=2
