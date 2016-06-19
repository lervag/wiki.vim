" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

if exists('b:current_syntax') | finish | endif
let b:current_syntax = "vimwiki"

syntax spell toplevel
let s:conceal = exists("+conceallevel") ? ' conceal' : ''
let s:options = ' contained transparent contains=NONE' . s:conceal

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
  return g:vimwiki_rxWikiLink1InvalidPrefix
        \ . a:target
        \ . g:vimwiki_rxWikiLink1InvalidSuffix
endfunction

" }}}
function! s:existing_mkd_refs() " {{{
  call vimwiki#markdown_base#reset_mkd_refs()
  return keys(vimwiki#markdown_base#get_reflinks())
endfunction

" }}}

" {{{ Regexes
let g:vimwiki_rxItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_'.
      \'\%([^_`[:space:]][^_`]*[^_`[:space:]]\|[^_`[:space:]]\)'.
      \'_'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_rxBoldItalic = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*_'.
      \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
      \'_\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_rxItalicBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'_\*'.
      \'\%([^*_`[:space:]][^*_`]*[^*_`[:space:]]\|[^*_`[:space:]]\)'.
      \'\*_'.
      \'\%([[:punct:]]\|\s\|$\)\@='
let g:vimwiki_rxCode = '`[^`]\+`'
let g:vimwiki_rxDelText = '\~\~[^~`]\+\~\~'
let g:vimwiki_rxSuperScript = '\^[^^`]\+\^'
let g:vimwiki_rxSubScript = ',,[^,`]\+,,'
let g:vimwiki_rxHR = '^-----*$'
let g:vimwiki_rxListDefine = '::\%(\s\|$\)'
let g:vimwiki_rxComment = '^\s*%%.*$'
let g:vimwiki_rxTags = '\%(^\|\s\)\@<=:\%([^:[:space:]]\+:\)\+\%(\s\|$\)\@='

let g:vimwiki_rxPreStart = '^\s*'.g:vimwiki_rxPreStart
let g:vimwiki_rxPreEnd = '^\s*'.g:vimwiki_rxPreEnd.'\s*$'

let g:vimwiki_rxMathStart = '^\s*'.g:vimwiki_rxMathStart
let g:vimwiki_rxMathEnd = '^\s*'.g:vimwiki_rxMathEnd.'\s*$'

" }}}

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

"
" template for matching all wiki links with a given target file
"
let g:vimwiki_WikiLinkMatchUrlTemplate =
      \ s:rx_wikilink_prefix .
      \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
      \ s:rx_wikilink_suffix .
      \ '\|' .
      \ s:rx_wikilink_prefix .
      \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
      \ s:rx_wikilink_separator .
      \ '.*' .
      \ s:rx_wikilink_suffix

let s:valid_chars = '[^\\\]]'
let g:vimwiki_rxWikiLinkUrl = s:valid_chars.'\{-}'
let g:vimwiki_rxWikiLinkDescr = s:valid_chars.'\{-}'

" this regexp defines what can form a link when the user presses <CR> in the
" buffer (and not on a link) to create a link
" basically, it's Ascii alphanumeric characters plus #|./@-_~ plus all
" non-Ascii characters
let g:vimwiki_rxWord = '[^[:blank:]!"$%&''()*+,:;<=>?\[\]\\^`{}]\+'

" match all
let g:vimwiki_rxWikiLink = s:rx_wikilink_prefix.
      \ g:vimwiki_rxWikiLinkUrl.'\%('.s:rx_wikilink_separator.
      \ g:vimwiki_rxWikiLinkDescr.'\)\?'.s:rx_wikilink_suffix

" match URL
let g:vimwiki_rxWikiLinkMatchUrl = s:rx_wikilink_prefix.
      \ '\zs'. g:vimwiki_rxWikiLinkUrl.'\ze\%('. s:rx_wikilink_separator.
      \ g:vimwiki_rxWikiLinkDescr.'\)\?'.s:rx_wikilink_suffix

" match DESCRIPTION
let g:vimwiki_rxWikiLinkMatchDescr = s:rx_wikilink_prefix.
      \ g:vimwiki_rxWikiLinkUrl.s:rx_wikilink_separator.'\%('.
      \ '\zs'. g:vimwiki_rxWikiLinkDescr. '\ze\)\?'. s:rx_wikilink_suffix

" }}}

"
" Syntax helper
"
let s:rx_wikilink_prefix1 = s:rx_wikilink_prefix . g:vimwiki_rxWikiLinkUrl .
      \ s:rx_wikilink_separator
let s:rx_wikilink_suffix1 = s:rx_wikilink_suffix

" LINKS: Setup weblink regexps {{{
" 0. URL : free-standing links: keep URL UR(L) strip trailing punct: URL; URL) UR(L))
" let g:vimwiki_rxWeblink = '[\["(|]\@<!'. g:vimwiki_rxWeblinkUrl .
      " \ '\%([),:;.!?]\=\%([ \t]\|$\)\)\@='
" Maxim:
" Simplify free-standing links: URL starts with non(letter|digit)scheme till
" the whitespace.
" Stuart, could you check it with markdown templated links? [](http://...), as
" the last bracket is the part of URL now?
let g:vimwiki_rxWeblink = '\<'. g:vimwiki_rxWeblinkUrl . '\S*'
" 0a) match URL within URL
let g:vimwiki_rxWeblinkMatchUrl = g:vimwiki_rxWeblink
" 0b) match DESCRIPTION within URL
let g:vimwiki_rxWeblinkMatchDescr = ''
" }}}

" LINKS: setup wikilink0 regexps {{{
" 0. [[URL]], or [[URL|DESCRIPTION]]

" 0a) match [[URL|DESCRIPTION]]
let g:vimwiki_rxWikiLink0 = g:vimwiki_rxWikiLink
" 0b) match URL within [[URL|DESCRIPTION]]
let g:vimwiki_rxWikiLink0MatchUrl = g:vimwiki_rxWikiLinkMatchUrl
" 0c) match DESCRIPTION within [[URL|DESCRIPTION]]
let g:vimwiki_rxWikiLink0MatchDescr = g:vimwiki_rxWikiLinkMatchDescr
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
"
let g:vimwiki_WikiLinkMatchUrlTemplate .=
      \ '\|' .
      \ s:rx_wikilink_md_prefix .
      \ '.*' .
      \ s:rx_wikilink_md_separator .
      \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
      \ s:rx_wikilink_md_suffix .
      \ '\|' .
      \ s:rx_wikilink_md_prefix .
      \ '\zs__LinkUrl__\ze\%(#.*\)\?' .
      \ s:rx_wikilink_md_separator .
      \ s:rx_wikilink_md_suffix

let s:valid_chars = '[^\\\[\]]'
let g:vimwiki_rxWikiLink1Url = s:valid_chars.'\{-}'
let g:vimwiki_rxWikiLink1Descr = s:valid_chars.'\{-}'

let g:vimwiki_rxWikiLink1InvalidPrefix = '[\]\[]\@<!'
let g:vimwiki_rxWikiLink1InvalidSuffix = '[\]\[]\@!'
let s:rx_wikilink_md_prefix = g:vimwiki_rxWikiLink1InvalidPrefix.
      \ s:rx_wikilink_md_prefix
let s:rx_wikilink_md_suffix = s:rx_wikilink_md_suffix.
      \ g:vimwiki_rxWikiLink1InvalidSuffix

"
" 1. [URL][], [DESCRIPTION][URL]
" 1a) match [URL][], [DESCRIPTION][URL]
let g:vimwiki_rxWikiLink1 = s:rx_wikilink_md_prefix.
    \ g:vimwiki_rxWikiLink1Url. s:rx_wikilink_md_separator.
    \ s:rx_wikilink_md_suffix.
    \ '\|'. s:rx_wikilink_md_prefix.
    \ g:vimwiki_rxWikiLink1Descr.s:rx_wikilink_md_separator.
    \ g:vimwiki_rxWikiLink1Url.s:rx_wikilink_md_suffix
" 1b) match URL within [URL][], [DESCRIPTION][URL]
let g:vimwiki_rxWikiLink1MatchUrl = s:rx_wikilink_md_prefix.
    \ '\zs'. g:vimwiki_rxWikiLink1Url. '\ze'. s:rx_wikilink_md_separator.
    \ s:rx_wikilink_md_suffix.
    \ '\|'. s:rx_wikilink_md_prefix.
    \ g:vimwiki_rxWikiLink1Descr. s:rx_wikilink_md_separator.
    \ '\zs'. g:vimwiki_rxWikiLink1Url. '\ze'. s:rx_wikilink_md_suffix
" 1c) match DESCRIPTION within [DESCRIPTION][URL]
let g:vimwiki_rxWikiLink1MatchDescr = s:rx_wikilink_md_prefix.
    \ '\zs'. g:vimwiki_rxWikiLink1Descr.'\ze'. s:rx_wikilink_md_separator.
    \ g:vimwiki_rxWikiLink1Url.s:rx_wikilink_md_suffix
" }}}

" LINKS: Syntax helper {{{
let g:vimwiki_rxWikiLink1Prefix1 = s:rx_wikilink_md_prefix
let g:vimwiki_rxWikiLink1Suffix1 = s:rx_wikilink_md_separator.
      \ g:vimwiki_rxWikiLink1Url.s:rx_wikilink_md_suffix
" }}}

" *. ANY wikilink {{{
" *a) match ANY wikilink
let g:vimwiki_rxWikiLink = ''.
    \ g:vimwiki_rxWikiLink0.'\|'.
    \ g:vimwiki_rxWikiLink1
" *b) match URL within ANY wikilink
let g:vimwiki_rxWikiLinkMatchUrl = ''.
    \ g:vimwiki_rxWikiLink0MatchUrl.'\|'.
    \ g:vimwiki_rxWikiLink1MatchUrl
" *c) match DESCRIPTION within ANY wikilink
let g:vimwiki_rxWikiLinkMatchDescr = ''.
    \ g:vimwiki_rxWikiLink0MatchDescr.'\|'.
    \ g:vimwiki_rxWikiLink1MatchDescr
" }}}

" LINKS: Setup weblink0 regexps {{{
" 0. URL : free-standing links: keep URL UR(L) strip trailing punct: URL; URL) UR(L))
let g:vimwiki_rxWeblink0 = g:vimwiki_rxWeblink
" 0a) match URL within URL
let g:vimwiki_rxWeblinkMatchUrl0 = g:vimwiki_rxWeblinkMatchUrl
" 0b) match DESCRIPTION within URL
let g:vimwiki_rxWeblinkMatchDescr0 = g:vimwiki_rxWeblinkMatchDescr
" }}}

" LINKS: Setup weblink1 regexps {{{
let g:vimwiki_rxWeblink1Prefix = '['
let g:vimwiki_rxWeblink1Suffix = ')'
let g:vimwiki_rxWeblink1Separator = ']('

"
" [DESCRIPTION](URL)
"
let g:vimwiki_Weblink1Template = g:vimwiki_rxWeblink1Prefix . '__LinkDescription__'.
      \ g:vimwiki_rxWeblink1Separator. '__LinkUrl__'.
      \ g:vimwiki_rxWeblink1Suffix

let s:valid_chars = '[^\\]'

let g:vimwiki_rxWeblink1Prefix = vimwiki#u#escape(g:vimwiki_rxWeblink1Prefix)
let g:vimwiki_rxWeblink1Suffix = vimwiki#u#escape(g:vimwiki_rxWeblink1Suffix)
let g:vimwiki_rxWeblink1Separator = vimwiki#u#escape(g:vimwiki_rxWeblink1Separator)
let g:vimwiki_rxWeblink1Url = s:valid_chars.'\{-}'
let g:vimwiki_rxWeblink1Descr = s:valid_chars.'\{-}'

" match all
let g:vimwiki_rxWeblink1 = g:vimwiki_rxWeblink1Prefix.
      \ g:vimwiki_rxWeblink1Url.g:vimwiki_rxWeblink1Separator.
      \ g:vimwiki_rxWeblink1Descr.g:vimwiki_rxWeblink1Suffix

" match URL
let g:vimwiki_rxWeblink1MatchUrl = g:vimwiki_rxWeblink1Prefix.
      \ g:vimwiki_rxWeblink1Descr. g:vimwiki_rxWeblink1Separator.
      \ '\zs'.g:vimwiki_rxWeblink1Url.'\ze'. g:vimwiki_rxWeblink1Suffix

" match DESCRIPTION
let g:vimwiki_rxWeblink1MatchDescr = g:vimwiki_rxWeblink1Prefix.
      \ '\zs'.g:vimwiki_rxWeblink1Descr.'\ze'. g:vimwiki_rxWeblink1Separator.
      \ g:vimwiki_rxWeblink1Url. g:vimwiki_rxWeblink1Suffix
" }}}

" Syntax helper {{{
" TODO: image links too !!
" let g:vimwiki_rxWeblink1Prefix1 = '!\?'. g:vimwiki_rxWeblink1Prefix
let g:vimwiki_rxWeblink1Prefix1 = g:vimwiki_rxWeblink1Prefix
let g:vimwiki_rxWeblink1Suffix1 = g:vimwiki_rxWeblink1Separator.
      \ g:vimwiki_rxWeblink1Url.g:vimwiki_rxWeblink1Suffix
" }}}

" *. ANY weblink {{{
" *a) match ANY weblink
let g:vimwiki_rxWeblink = ''.
    \ g:vimwiki_rxWeblink1.'\|'.
    \ g:vimwiki_rxWeblink0
" *b) match URL within ANY weblink
let g:vimwiki_rxWeblinkMatchUrl = ''.
    \ g:vimwiki_rxWeblink1MatchUrl.'\|'.
    \ g:vimwiki_rxWeblinkMatchUrl0
" *c) match DESCRIPTION within ANY weblink
let g:vimwiki_rxWeblinkMatchDescr = ''.
    \ g:vimwiki_rxWeblink1MatchDescr.'\|'.
    \ g:vimwiki_rxWeblinkMatchDescr0
" }}}

let g:vimwiki_rxAnyLink = g:vimwiki_rxWikiLink . '\|' . g:vimwiki_rxWeblink

" LINKS: setup wikilink1 reference link definitions {{{
let g:vimwiki_rxMkdRef = '\['.g:vimwiki_rxWikiLinkDescr.']:\%(\s\+\|\n\)'.
      \ g:vimwiki_rxWeblink0
let g:vimwiki_rxMkdRefMatchDescr = '\[\zs'.g:vimwiki_rxWikiLinkDescr.'\ze]:\%(\s\+\|\n\)'.
      \ g:vimwiki_rxWeblink0
let g:vimwiki_rxMkdRefMatchUrl = '\['.g:vimwiki_rxWikiLinkDescr.']:\%(\s\+\|\n\)\zs'.
      \ g:vimwiki_rxWeblink0.'\ze'
" }}}

" }}} end of Links

" {{{ Link targets

call s:add_target_syntax(g:vimwiki_rxWikiLink, 'VimwikiLink')
call s:add_target_syntax(g:vimwiki_rxWikiLink1, 'VimwikiWikiLink1')
call s:add_target_syntax(g:vimwiki_rxWeblink, 'VimwikiLink')
call s:add_target_syntax(g:vimwiki_rxWeblink1, 'VimwikiWeblink1')

" WikiLink
" All remaining schemes are highlighted automatically
let s:rxSchemes = '\%('.
      \ join(split(g:vimwiki_schemes, '\s*,\s*'), '\|').'\|'.
      \ join(split(g:vimwiki_web_schemes1, '\s*,\s*'), '\|').
      \ '\):'

"
" [[nonwiki-scheme-URL]]
"
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate1),
      \ s:rxSchemes.g:vimwiki_rxWikiLinkUrl, g:vimwiki_rxWikiLinkDescr, '')
call s:add_target_syntax(s:target, 'VimwikiLink')

"
" [[nonwiki-scheme-URL|DESCRIPTION]]
"
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLinkTemplate2),
      \ s:rxSchemes.g:vimwiki_rxWikiLinkUrl, g:vimwiki_rxWikiLinkDescr, '')
call s:add_target_syntax(s:target, 'VimwikiLink')

"
" [nonwiki-scheme-URL]
"
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLink1Template1),
      \ s:rxSchemes.g:vimwiki_rxWikiLink1Url, g:vimwiki_rxWikiLink1Descr, '')
call s:add_target_syntax(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')

"
" [DESCRIPTION][nonwiki-scheme-URL]
"
let s:target = vimwiki#base#apply_template(
      \ vimwiki#u#escape(g:vimwiki_WikiLink1Template2),
      \ s:rxSchemes.g:vimwiki_rxWikiLink1Url, g:vimwiki_rxWikiLink1Descr, '')
call s:add_target_syntax(s:wrap_wikilink1_rx(s:target), 'VimwikiWikiLink1')

" }}}

" {{{ Headers

for s:i in range(1,6)
  let g:vimwiki_rxH{s:i}_Template = repeat(g:vimwiki_rxH, s:i).' __Header__'
  let g:vimwiki_rxH{s:i} = '^\s*'.g:vimwiki_rxH.'\{'.s:i.'}[^'.g:vimwiki_rxH.'].*$'
  let g:vimwiki_rxH{s:i}_Start = '^\s*'.g:vimwiki_rxH.'\{'.s:i.'}[^'.g:vimwiki_rxH.'].*$'
  let g:vimwiki_rxH{s:i}_End = '^\s*'.g:vimwiki_rxH.'\{1,'.s:i.'}[^'.g:vimwiki_rxH.'].*$'
endfor
let g:vimwiki_rxHeader = '^\s*\('.g:vimwiki_rxH.'\{1,6}\)\zs[^'.g:vimwiki_rxH.'].*\ze$'

for s:i in range(1,6)
  execute 'syntax match VimwikiHeader'.s:i.' /'.g:vimwiki_rxH{s:i}.'/ contains=VimwikiTodo,VimwikiHeaderChar,VimwikiNoExistsLink,VimwikiCode,VimwikiLink,VimwikiWeblink1,VimwikiWikiLink1,@Spell'
endfor

" }}}1

" possibly concealed chars " {{{
execute 'syn match VimwikiEqInChar contained /\$/'.s:conceal
execute 'syn match VimwikiBoldChar contained /*/'.s:conceal
execute 'syn match VimwikiItalicChar contained /_/'.s:conceal
execute 'syn match VimwikiBoldItalicChar contained /\*_/'.s:conceal
execute 'syn match VimwikiItalicBoldChar contained /_\*/'.s:conceal
execute 'syn match VimwikiCodeChar contained /`/'.s:conceal
execute 'syn match VimwikiDelTextChar contained /\~\~/'.s:conceal
execute 'syn match VimwikiSuperScript contained /^/'.s:conceal
execute 'syn match VimwikiSubScript contained /,,/'.s:conceal
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
execute 'syn match VimwikiHeaderChar contained /\%(^\s*'.g:vimwiki_rxH.'\+\)\|\%('.g:vimwiki_rxH.'\+\s*$\)/'
syn match VimwikiEqInCharT contained /\$/
syn match VimwikiBoldCharT contained /*/
syn match VimwikiItalicCharT contained /_/
syn match VimwikiBoldItalicCharT contained /\*_/
syn match VimwikiItalicBoldCharT contained /_\*/
syn match VimwikiCodeCharT contained /`/
syn match VimwikiDelTextCharT contained /\~\~/
syn match VimwikiSuperScriptT contained /^/
syn match VimwikiSubScriptT contained /,,/

let g:vimwiki_rxTodo = '\C\%(TODO:\|DONE:\|STARTED:\|FIXME:\|FIXED:\|XXX:\)'
execute 'syntax match VimwikiTodo /'. g:vimwiki_rxTodo .'/'
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
execute 'syntax match VimwikiList /'.g:vimwiki_rxListItemWithoutCB.'/'
execute 'syntax match VimwikiList /'.g:vimwiki_rxListDefine.'/'
execute 'syntax match VimwikiListTodo /'.g:vimwiki_rxListItem.'/'
execute 'syntax match VimwikiCheckBoxDone /'.g:vimwiki_rxListItemWithoutCB.'\s*\['.g:vimwiki_listsyms_list[4].'\]\s.*$/ '.
      \ 'contains=VimwikiNoExistsLink,VimwikiLink,@Spell'

syntax match VimwikiEqIn  /\$[^$`]\+\$/ contains=VimwikiEqInChar
syntax match VimwikiEqInT /\$[^$`]\+\$/ contained contains=VimwikiEqInCharT

let g:vimwiki_rxBold = '\%(^\|\s\|[[:punct:]]\)\@<='.
      \'\*'.
      \'\%([^*`[:space:]][^*`]*[^*`[:space:]]\|[^*`[:space:]]\)'.
      \'\*'.
      \'\%([[:punct:]]\|\s\|$\)\@='
execute 'syntax match VimwikiBold /'.g:vimwiki_rxBold.'/ contains=VimwikiBoldChar,@Spell'
execute 'syntax match VimwikiBoldT /'.g:vimwiki_rxBold.'/ contained contains=VimwikiBoldCharT,@Spell'

execute 'syntax match VimwikiItalic /'.g:vimwiki_rxItalic.'/ contains=VimwikiItalicChar,@Spell'
execute 'syntax match VimwikiItalicT /'.g:vimwiki_rxItalic.'/ contained contains=VimwikiItalicCharT,@Spell'

execute 'syntax match VimwikiBoldItalic /'.g:vimwiki_rxBoldItalic.'/ contains=VimwikiBoldItalicChar,VimwikiItalicBoldChar,@Spell'
execute 'syntax match VimwikiBoldItalicT /'.g:vimwiki_rxBoldItalic.'/ contained contains=VimwikiBoldItalicChatT,VimwikiItalicBoldCharT,@Spell'

execute 'syntax match VimwikiItalicBold /'.g:vimwiki_rxItalicBold.'/ contains=VimwikiBoldItalicChar,VimwikiItalicBoldChar,@Spell'
execute 'syntax match VimwikiItalicBoldT /'.g:vimwiki_rxItalicBold.'/ contained contains=VimwikiBoldItalicCharT,VimsikiItalicBoldCharT,@Spell'

execute 'syntax match VimwikiDelText /'.g:vimwiki_rxDelText.'/ contains=VimwikiDelTextChar,@Spell'
execute 'syntax match VimwikiDelTextT /'.g:vimwiki_rxDelText.'/ contained contains=VimwikiDelTextChar,@Spell'

execute 'syntax match VimwikiSuperScript /'.g:vimwiki_rxSuperScript.'/ contains=VimwikiSuperScriptChar,@Spell'
execute 'syntax match VimwikiSuperScriptT /'.g:vimwiki_rxSuperScript.'/ contained contains=VimwikiSuperScriptCharT,@Spell'

execute 'syntax match VimwikiSubScript /'.g:vimwiki_rxSubScript.'/ contains=VimwikiSubScriptChar,@Spell'
execute 'syntax match VimwikiSubScriptT /'.g:vimwiki_rxSubScript.'/ contained contains=VimwikiSubScriptCharT,@Spell'

execute 'syntax match VimwikiCode /'.g:vimwiki_rxCode.'/ contains=VimwikiCodeChar'
execute 'syntax match VimwikiCodeT /'.g:vimwiki_rxCode.'/ contained contains=VimwikiCodeCharT'

" <hr> horizontal rule
execute 'syntax match VimwikiHR /'.g:vimwiki_rxHR.'/'

execute 'syntax region VimwikiPre start=/'.g:vimwiki_rxPreStart.
      \ '/ end=/'.g:vimwiki_rxPreEnd.'/ contains=@Spell'

execute 'syntax region VimwikiMath start=/'.g:vimwiki_rxMathStart.
      \ '/ end=/'.g:vimwiki_rxMathEnd.'/ contains=@Spell'


" tags
execute 'syntax match VimwikiTag /'.g:vimwiki_rxTags.'/'

" }}}

" concealed chars " {{{

execute 'syn match VimwikiWikiLink1Char /'.s:rx_wikilink_md_prefix.'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.s:rx_wikilink_md_suffix.'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.g:vimwiki_rxWikiLink1Prefix1.'/'.s:options
execute 'syn match VimwikiWikiLink1Char /'.g:vimwiki_rxWikiLink1Suffix1.'/'.s:options
execute 'syn match VimwikiWeblink1Char "'.g:vimwiki_rxWeblink1Prefix1.'"'.s:options
execute 'syn match VimwikiWeblink1Char "'.g:vimwiki_rxWeblink1Suffix1.'"'.s:options
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
for [s:hl_syntax, s:vim_syntax] in items(vimwiki#base#detect_nested_syntax())
  call vimwiki#base#nested_syntax(s:vim_syntax,
        \ g:vimwiki_rxPreStart.'\%(.*[[:blank:][:punct:]]\)\?'.
        \ s:hl_syntax.'\%([[:blank:][:punct:]].*\)\?',
        \ g:vimwiki_rxPreEnd, 'VimwikiPre')
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
