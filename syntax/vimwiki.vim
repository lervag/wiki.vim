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
  return g:vimwiki.rx.link_wiki1_inv_pref
        \ . a:target
        \ . g:vimwiki.rx.link_wiki1_inv_suff
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

" LINKS: setup of larger regexes {{{

" [[URL]] and [[URL|DESCRIPTION]] {{{

let s:wikilink_prefix = '[['
let s:wikilink_suffix = ']]'
let s:wikilink_separator = '|'
let s:rx_wikilink_prefix = vimwiki#u#escape(s:wikilink_prefix) . '\/\?'
let s:rx_wikilink_suffix = vimwiki#u#escape(s:wikilink_suffix)
let s:rx_wikilink_separator = vimwiki#u#escape(s:wikilink_separator)

"
" [[URL]]
"
let g:vimwiki_WikiLinkTemplate1 = s:wikilink_prefix . '__LinkUrl__'.
      \ s:wikilink_suffix

"
" [[URL|DESCRIPTION]]
"
let g:vimwiki_WikiLinkTemplate2 = s:wikilink_prefix . '__LinkUrl__'.
      \ s:wikilink_separator . '__LinkDescription__' . s:wikilink_suffix


let g:vimwiki.rx.link_wiki_url = '[^\\\]]\{-}'
let g:vimwiki.rx.link_wiki_text = '[^\\\]]\{-}'

" this regexp defines what can form a link when the user presses <CR> in the
" buffer (and not on a link) to create a link
" basically, it's Ascii alphanumeric characters plus #|./@-_~ plus all
" non-Ascii characters
let g:vimwiki.rx.word = '[^[:blank:]!"$%&''()*+,:;<=>?\[\]\\^`{}]\+'

" match all
let g:vimwiki.rx.link_wiki = s:rx_wikilink_prefix.
      \ g:vimwiki.rx.link_wiki_url.'\%('.s:rx_wikilink_separator.
      \ g:vimwiki.rx.link_wiki_text.'\)\?'.s:rx_wikilink_suffix

" match URL
let g:vimwiki.rx.link_wiki_url = s:rx_wikilink_prefix.
      \ '\zs'. g:vimwiki.rx.link_wiki_url.'\ze\%('. s:rx_wikilink_separator.
      \ g:vimwiki.rx.link_wiki_text.'\)\?'.s:rx_wikilink_suffix

" match DESCRIPTION
let g:vimwiki.rx.link_wiki_text = s:rx_wikilink_prefix.
      \ g:vimwiki.rx.link_wiki_url.s:rx_wikilink_separator.'\%('.
      \ '\zs'. g:vimwiki.rx.link_wiki_text. '\ze\)\?'. s:rx_wikilink_suffix

" }}}

"
" Syntax helper
"
let s:rx_wikilink_prefix1 = s:rx_wikilink_prefix . g:vimwiki.rx.link_wiki_url .
      \ s:rx_wikilink_separator
let s:rx_wikilink_suffix1 = s:rx_wikilink_suffix


" LINKS: setup wikilink0 regexps {{{
" 0. [[URL]], or [[URL|DESCRIPTION]]

" 0a) match [[URL|DESCRIPTION]]
let g:vimwiki.rx.link_wiki0 = g:vimwiki.rx.link_wiki
" 0b) match URL within [[URL|DESCRIPTION]]
let g:vimwiki.rx.link_wiki_url0 = g:vimwiki.rx.link_wiki_url
" 0c) match DESCRIPTION within [[URL|DESCRIPTION]]
let g:vimwiki.rx.link_wiki_text0 = g:vimwiki.rx.link_wiki_text
" }}}

" LINKS: setup wikilink1 regexps {{{
" 1. [URL][], or [DESCRIPTION][URL]

let s:wikilink_md_prefix = '['
let s:wikilink_md_suffix = ']'
let s:wikilink_md_separator = ']['
let s:rx_wikilink_md_prefix = vimwiki#u#escape(s:wikilink_md_prefix)
let s:rx_wikilink_md_suffix = vimwiki#u#escape(s:wikilink_md_suffix)
let s:rx_wikilink_md_separator = vimwiki#u#escape(s:wikilink_md_separator)

" [URL][]
let g:vimwiki_WikiLink1Template1 = s:wikilink_md_prefix . '__LinkUrl__'.
      \ s:wikilink_md_separator. s:wikilink_md_suffix
" [DESCRIPTION][URL]
let g:vimwiki_WikiLink1Template2 = s:wikilink_md_prefix. '__LinkDescription__'.
    \ s:wikilink_md_separator. '__LinkUrl__'.
    \ s:wikilink_md_suffix

let s:valid_chars = '[^\\\[\]]'
let g:vimwiki.rx.wikiLink1Url = s:valid_chars.'\{-}'
let g:vimwiki.rx.wikiLink1Descr = s:valid_chars.'\{-}'

let g:vimwiki.rx.link_wiki1_inv_pref = '[\]\[]\@<!'
let g:vimwiki.rx.link_wiki1_inv_suff = '[\]\[]\@!'
let s:rx_wikilink_md_prefix = g:vimwiki.rx.link_wiki1_inv_pref.
      \ s:rx_wikilink_md_prefix
let s:rx_wikilink_md_suffix = s:rx_wikilink_md_suffix.
      \ g:vimwiki.rx.link_wiki1_inv_suff

"
" 1. [URL][], [DESCRIPTION][URL]
" 1a) match [URL][], [DESCRIPTION][URL]
let g:vimwiki.rx.link_wiki1 = s:rx_wikilink_md_prefix.
    \ g:vimwiki.rx.wikiLink1Url. s:rx_wikilink_md_separator.
    \ s:rx_wikilink_md_suffix.
    \ '\|'. s:rx_wikilink_md_prefix.
    \ g:vimwiki.rx.wikiLink1Descr.s:rx_wikilink_md_separator.
    \ g:vimwiki.rx.wikiLink1Url.s:rx_wikilink_md_suffix
" 1b) match URL within [URL][], [DESCRIPTION][URL]
let g:vimwiki.rx.link_wiki_url1 = s:rx_wikilink_md_prefix.
    \ '\zs'. g:vimwiki.rx.wikiLink1Url. '\ze'. s:rx_wikilink_md_separator.
    \ s:rx_wikilink_md_suffix.
    \ '\|'. s:rx_wikilink_md_prefix.
    \ g:vimwiki.rx.wikiLink1Descr. s:rx_wikilink_md_separator.
    \ '\zs'. g:vimwiki.rx.wikiLink1Url. '\ze'. s:rx_wikilink_md_suffix
" 1c) match DESCRIPTION within [DESCRIPTION][URL]
let g:vimwiki.rx.link_wiki_text1 = s:rx_wikilink_md_prefix.
    \ '\zs'. g:vimwiki.rx.wikiLink1Descr.'\ze'. s:rx_wikilink_md_separator.
    \ g:vimwiki.rx.wikiLink1Url.s:rx_wikilink_md_suffix
" }}}

" LINKS: Syntax helper {{{
let g:vimwiki.rx.link_wiki_pre11 = s:rx_wikilink_md_prefix
let g:vimwiki.rx.link_wiki_suff11 = s:rx_wikilink_md_separator.
      \ g:vimwiki.rx.wikiLink1Url.s:rx_wikilink_md_suffix
" }}}

" *. ANY wikilink {{{
" *a) match ANY wikilink
let g:vimwiki.rx.link_wiki = ''.
    \ g:vimwiki.rx.link_wiki0.'\|'.
    \ g:vimwiki.rx.link_wiki1
" *b) match URL within ANY wikilink
let g:vimwiki.rx.link_wiki_url = ''.
    \ g:vimwiki.rx.link_wiki_url0.'\|'.
    \ g:vimwiki.rx.link_wiki_url1
" *c) match DESCRIPTION within ANY wikilink
let g:vimwiki.rx.link_wiki_text = ''.
    \ g:vimwiki.rx.link_wiki_text0.'\|'.
    \ g:vimwiki.rx.link_wiki_text1
" }}}

let g:vimwiki.rx.link_web0 = g:vimwiki.rx.link_web
let g:vimwiki.rx.link_web_url0 = g:vimwiki.rx.link_web_url
let g:vimwiki.rx.link_web_text0 = g:vimwiki.rx.link_web_text

" LINKS: Setup weblink1 regexps {{{
let g:vimwiki.rx.weblink1Prefix = '['
let g:vimwiki.rx.weblink1Suffix = ')'
let g:vimwiki.rx.weblink1Separator = ']('

"
" [DESCRIPTION](URL)
"
let g:vimwiki_Weblink1Template = g:vimwiki.rx.weblink1Prefix . '__LinkDescription__'.
      \ g:vimwiki.rx.weblink1Separator. '__LinkUrl__'.
      \ g:vimwiki.rx.weblink1Suffix

let s:valid_chars = '[^\\]'

let g:vimwiki.rx.weblink1Prefix = vimwiki#u#escape(g:vimwiki.rx.weblink1Prefix)
let g:vimwiki.rx.weblink1Suffix = vimwiki#u#escape(g:vimwiki.rx.weblink1Suffix)
let g:vimwiki.rx.weblink1Separator = vimwiki#u#escape(g:vimwiki.rx.weblink1Separator)
let g:vimwiki.rx.weblink1Url = s:valid_chars.'\{-}'
let g:vimwiki.rx.weblink1Descr = s:valid_chars.'\{-}'

" match all
let g:vimwiki.rx.link_web1 = g:vimwiki.rx.weblink1Prefix.
      \ g:vimwiki.rx.weblink1Url.g:vimwiki.rx.weblink1Separator.
      \ g:vimwiki.rx.weblink1Descr.g:vimwiki.rx.weblink1Suffix

" match URL
let g:vimwiki.rx.link_web_url1 = g:vimwiki.rx.weblink1Prefix.
      \ g:vimwiki.rx.weblink1Descr. g:vimwiki.rx.weblink1Separator.
      \ '\zs'.g:vimwiki.rx.weblink1Url.'\ze'. g:vimwiki.rx.weblink1Suffix

" match DESCRIPTION
let g:vimwiki.rx.link_web_text1 = g:vimwiki.rx.weblink1Prefix.
      \ '\zs'.g:vimwiki.rx.weblink1Descr.'\ze'. g:vimwiki.rx.weblink1Separator.
      \ g:vimwiki.rx.weblink1Url. g:vimwiki.rx.weblink1Suffix
" }}}

" Syntax helper {{{
" TODO: image links too !!
" let g:vimwiki.rx.link_web_pre11 = '!\?'. g:vimwiki.rx.weblink1Prefix
let g:vimwiki.rx.link_web_pre11 = g:vimwiki.rx.weblink1Prefix
let g:vimwiki.rx.link_web_suff11 = g:vimwiki.rx.weblink1Separator.
      \ g:vimwiki.rx.weblink1Url.g:vimwiki.rx.weblink1Suffix
" }}}

" *. ANY weblink {{{
" *a) match ANY weblink
let g:vimwiki.rx.link_web = ''.
    \ g:vimwiki.rx.link_web1.'\|'.
    \ g:vimwiki.rx.link_web0
" *b) match URL within ANY weblink
let g:vimwiki.rx.link_web_url = ''.
    \ g:vimwiki.rx.link_web_url1.'\|'.
    \ g:vimwiki.rx.link_web_url0
" *c) match DESCRIPTION within ANY weblink
let g:vimwiki.rx.link_web_text = ''.
    \ g:vimwiki.rx.link_web_text1.'\|'.
    \ g:vimwiki.rx.link_web_text0
" }}}

let g:vimwiki.rx.link_any = g:vimwiki.rx.link_wiki . '\|' . g:vimwiki.rx.link_web


let g:vimwiki.rx.mkd_ref = '\['.g:vimwiki.rx.link_wiki_text.']:\%(\s\+\|\n\)'.
      \ g:vimwiki.rx.link_web0
let g:vimwiki.rx.mkd_ref_text = '\[\zs'.g:vimwiki.rx.link_wiki_text.'\ze]:\%(\s\+\|\n\)'.
      \ g:vimwiki.rx.link_web0
let g:vimwiki.rx.mkd_ref_url = '\['.g:vimwiki.rx.link_wiki_text.']:\%(\s\+\|\n\)\zs'.
      \ g:vimwiki.rx.link_web0.'\ze'


" }}} end of Links

" {{{ Link targets

call s:add_target_syntax(g:vimwiki.rx.link_wiki, 'VimwikiLink')
call s:add_target_syntax(g:vimwiki.rx.link_wiki1, 'VimwikiWikiLink1')
call s:add_target_syntax(g:vimwiki.rx.link_web, 'VimwikiLink')
call s:add_target_syntax(g:vimwiki.rx.link_web1, 'VimwikiWeblink1')

" WikiLink
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\w\+:'

" [[nonwiki-scheme-URL]]
let s:target = s:apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate1),
      \ s:rxSchemes.g:vimwiki.rx.link_wiki_url, g:vimwiki.rx.link_wiki_text)
call s:add_target_syntax(s:target, 'VimwikiLink')

" [[nonwiki-scheme-URL|DESCRIPTION]]
let s:target = s:apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate2),
      \ s:rxSchemes.g:vimwiki.rx.link_wiki_url, g:vimwiki.rx.link_wiki_text)
call s:add_target_syntax(s:target, 'VimwikiLink')

" [nonwiki-scheme-URL]
let s:target = s:apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLink1Template1),
      \ s:rxSchemes.g:vimwiki.rx.wikiLink1Url, g:vimwiki.rx.wikiLink1Descr)
call s:add_target_syntax(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')

" [DESCRIPTION][nonwiki-scheme-URL]
let s:target = s:apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLink1Template2),
      \ s:rxSchemes.g:vimwiki.rx.wikiLink1Url, g:vimwiki.rx.wikiLink1Descr)
call s:add_target_syntax(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')

" }}}

" {{{ Headers

for s:i in range(1,6)
  let g:vimwiki_rxH{s:i}_Template = repeat(g:vimwiki.rx.H, s:i).' __Header__'
  let g:vimwiki_rxH{s:i} = '^\s*'.g:vimwiki.rx.H.'\{'.s:i.'}[^'.g:vimwiki.rx.H.'].*$'
  let g:vimwiki_rxH{s:i}_Start = '^\s*'.g:vimwiki.rx.H.'\{'.s:i.'}[^'.g:vimwiki.rx.H.'].*$'
  let g:vimwiki_rxH{s:i}_End = '^\s*'.g:vimwiki.rx.H.'\{1,'.s:i.'}[^'.g:vimwiki.rx.H.'].*$'
endfor
let g:vimwiki.rx.header = '^\s*\('.g:vimwiki.rx.H.'\{1,6}\)\zs[^'.g:vimwiki.rx.H.'].*\ze$'

for s:i in range(1,6)
  execute 'syntax match VimwikiHeader'.s:i.' /'.g:vimwiki_rxH{s:i}.'/ contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,VimwikiCode,VimwikiLink,VimwikiWeblink1,VimwikiWikiLink1,@Spell'
endfor

" }}}1

" possibly concealed chars " {{{
syn match VimwikiEqInChar       contained /\$/   conceal
syn match VimwikiBoldChar       contained /*/    conceal
syn match VimwikiItalicChar     contained /_/    conceal
syn match VimwikiBoldItalicChar contained /\*_/  conceal
syn match VimwikiItalicBoldChar contained /_\*/  conceal
syn match VimwikiCodeChar       contained /`/    conceal
syn match VimwikiDelTextChar    contained /\~\~/ conceal
syn match VimwikiSuperScript    contained /^/    conceal
syn match VimwikiSubScript      contained /,,/   conceal
" }}}

" concealed link parts " {{{

" A shortener for long URLs: LinkRest (a middle part of the URL) is concealed
" VimwikiLinkRest group is left undefined if link shortening is not desired
execute 'syn match VimwikiLinkRest `\%(///\=[^/ \t]\+/\)\zs\S\+\ze'
      \.'\%([/#?]\w\|\S\{15}\)`'.' cchar=~'.s:options

" conceal wikilinks
execute 'syn match VimwikiLinkChar /'.s:rx_wikilink_prefix.'/'.s:options
execute 'syn match VimwikiLinkChar /'.s:rx_wikilink_suffix.'/'.s:options
execute 'syn match VimwikiLinkChar /'.s:rx_wikilink_prefix1.'/'.s:options
execute 'syn match VimwikiLinkChar /'.s:rx_wikilink_suffix1.'/'.s:options

" }}}

" non concealed chars " {{{
execute 'syn match VimwikiHeaderChar contained /\%(^\s*'.g:vimwiki.rx.H.'\+\)\|\%('.g:vimwiki.rx.H.'\+\s*$\)/'
syn match VimwikiEqInCharT contained /\$/
syn match VimwikiBoldCharT contained /*/
syn match VimwikiItalicCharT contained /_/
syn match VimwikiBoldItalicCharT contained /\*_/
syn match VimwikiItalicBoldCharT contained /_\*/
syn match VimwikiCodeCharT contained /`/
syn match VimwikiDelTextCharT contained /\~\~/
syn match VimwikiSuperScriptT contained /^/
syn match VimwikiSubScriptT contained /,,/

let g:vimwiki.rx.todo = '\C\%(TODO:\|DONE:\|STARTED:\|FIXME:\|FIXED:\|XXX:\)'
execute 'syntax match VimwikiTodo /'. g:vimwiki.rx.todo .'/'
" }}}

" main syntax groups {{{

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

let g:vimwiki.rx.bold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*'.
      \'\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)'.
      \'\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='
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

" concealed chars " {{{

execute 'syn match VimwikiWikiLink1Char /'.s:rx_wikilink_md_prefix.'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.s:rx_wikilink_md_suffix.'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.g:vimwiki.rx.link_wiki_pre11.'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.g:vimwiki.rx.link_wiki_suff11.'/'.s:options
execute 'syn match VimwikiWeblink1Char "'.g:vimwiki.rx.link_web_pre11.'"'.s:options
execute 'syn match VimwikiWeblink1Char "'.g:vimwiki.rx.link_web_suff11.'"'.s:options
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

"
" Nested syntax
"
for [s:hl_syntax, s:vim_syntax] in items(vimwiki#syntax#detect_nested())
  call vimwiki#syntax#add_nested(s:vim_syntax,
        \ g:vimwiki.rx.preStart.'\%(.*[[:blank:][:punct:]]\)\?'.
        \ s:hl_syntax.'\%([[:blank:][:punct:]].*\)\?',
        \ g:vimwiki.rx.preEnd, 'VimwikiPre')
endfor

"
" Minor additional diary syntax
"
if !expand('%:p') =~ 'wiki\/journal' | finish | endif

" Set spell option
syntax spell default

" Standard syntax elements
syn match TODO    /TODO/
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
hi link TODO    TODO

" vim: fdm=marker sw=2
