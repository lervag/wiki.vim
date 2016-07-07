" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

"
" Generated regexes
"
function! vimwiki#rx#link() " {{{1
  if !exists('s:rx.link')
    let s:rx.link = join(
        \ map(vimwiki#link#get_matchers_links(), 'v:val.rx'), '\|')
  endif

  return s:rx.link
endfunction

" }}}1
function! vimwiki#rx#surrounded(word, chars) " {{{1
  return '\%(^\|\s\|[[:punct:]]\)\@<='
        \ . escape(a:chars, '*')
        \ . a:word
        \ . escape(join(reverse(split(a:chars, '\zs')), ''), '*')
        \ . '\%([[:punct:]]\|\s\|$\)\@='
endfunction

" }}}1

"
" Common getters
"
function! vimwiki#rx#word() " {{{1
  return s:rx.word
endfunction

" }}}1
function! vimwiki#rx#pre_beg() " {{{1
  return s:rx.pre_beg
endfunction

" }}}1
function! vimwiki#rx#pre_end() " {{{1
  return s:rx.pre_end
endfunction

" }}}1
function! vimwiki#rx#super() " {{{1
  return s:rx.super
endfunction

" }}}1
function! vimwiki#rx#sub() " {{{1
  return s:rx.sub
endfunction

" }}}1
function! vimwiki#rx#list_define() " {{{1
  return s:rx.list_define
endfunction

" }}}1
function! vimwiki#rx#comment() " {{{1
  return s:rx.comment
endfunction

" }}}1
function! vimwiki#rx#todo() " {{{1
  return s:rx.todo
endfunction

" }}}1
function! vimwiki#rx#header() " {{{1
  return s:rx.header
endfunction

" }}}1
function! vimwiki#rx#header_items() " {{{1
  return s:rx.header_items
endfunction

" }}}1
function! vimwiki#rx#bold() " {{{1
  return s:rx.bold
endfunction

" }}}1
function! vimwiki#rx#italic() " {{{1
  return s:rx.italic
endfunction

" }}}1
function! vimwiki#rx#bold_italic() " {{{1
  return s:rx.bold_italic
endfunction

" }}}1
function! vimwiki#rx#italic_bold() " {{{1
  return s:rx.italic_bold
endfunction

" }}}1

" {{{1 Define regexes

let s:rx = {}
let s:rx.word = '[^[:blank:]!"$%&''()*+,:;<=>?\[\]\\^`{}]\+'
let s:rx.pre_beg = '^\s*```'
let s:rx.pre_end = '^\s*```\s*$'
let s:rx.super = '\^[^^`]\+\^'
let s:rx.sub = ',,[^,`]\+,,'
let s:rx.list_define = '::\%(\s\|$\)'
let s:rx.comment = '^\s*%%.*$'
let s:rx.todo = '\C\%(TODO\|DONE\|STARTED\|FIXME\|FIXED\):\?'
let s:rx.header = '^#\{1,6}\s*[^#].*'
let s:rx.header_items = '^\(#\{1,6}\)\s*\([^#].*\)\s*$'
let s:rx.bold = vimwiki#rx#surrounded(
      \ '[^*`[:space:]]\%([^*`]*[^*`[:space:]]\)\?', '*')
let s:rx.bold_italic = vimwiki#rx#surrounded(
      \ '[^*_`[:space:]]\%([^*_`]*[^*_`[:space:]]\)\?', '*_')
let s:rx.italic = vimwiki#rx#surrounded(
      \ '[^_`[:space:]]\%([^_`]*[^_`[:space:]]\)\?', '_')
let s:rx.italic_bold = vimwiki#rx#surrounded(
      \ '[^_*`[:space:]]\%([^_*`]*[^_*`[:space:]]\)\?', '_*')

" }}}1

" vim: fdm=marker sw=2
