" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
" License:    MIT license
"

"
" Generated regexes
"
function! wiki#rx#link() abort " {{{1
  if !exists('s:rx.link')
    let s:rx.link = join(
        \ map(wiki#link#get_matchers_links(), 'v:val.rx'), '\|')
  endif

  return s:rx.link
endfunction

" }}}1
function! wiki#rx#surrounded(word, chars) abort " {{{1
  return '\%(^\|\s\|[[:punct:]]\)\@<='
        \ . '\zs'
        \ . escape(a:chars, '*')
        \ . a:word
        \ . escape(join(reverse(split(a:chars, '')), ''), '*')
        \ . '\ze'
        \ . '\%([[:punct:]]\|\s\|$\)\@='
endfunction

" }}}1

"
" Common getters
"
function! wiki#rx#word() abort " {{{1
  return s:rx.word
endfunction

" }}}1
function! wiki#rx#pre_beg() abort " {{{1
  return s:rx.pre_beg
endfunction

" }}}1
function! wiki#rx#pre_end() abort " {{{1
  return s:rx.pre_end
endfunction

" }}}1
function! wiki#rx#super() abort " {{{1
  return s:rx.super
endfunction

" }}}1
function! wiki#rx#sub() abort " {{{1
  return s:rx.sub
endfunction

" }}}1
function! wiki#rx#list_define() abort " {{{1
  return s:rx.list_define
endfunction

" }}}1
function! wiki#rx#comment() abort " {{{1
  return s:rx.comment
endfunction

" }}}1
function! wiki#rx#todo() abort " {{{1
  return s:rx.todo
endfunction

" }}}1
function! wiki#rx#done() abort " {{{1
  return s:rx.done
endfunction

" }}}1
function! wiki#rx#header() abort " {{{1
  return s:rx.header
endfunction

" }}}1
function! wiki#rx#header_items() abort " {{{1
  return s:rx.header_items
endfunction

" }}}1
function! wiki#rx#bold() abort " {{{1
  return s:rx.bold
endfunction

" }}}1
function! wiki#rx#italic() abort " {{{1
  return s:rx.italic
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
let s:rx.todo = '\C\%(TODO\|STARTED\|FIXME\):\?'
let s:rx.done = '\C\%(OK\|DONE\|FIXED\):\?'
let s:rx.header = '^#\{1,6}\s*[^#].*'
let s:rx.header_items = '^\(#\{1,6}\)\s*\([^#].*\)\s*$'
let s:rx.bold = wiki#rx#surrounded(
      \ '[^*`[:space:]]\%([^*`]*[^*`[:space:]]\)\?', '*')
let s:rx.italic = wiki#rx#surrounded(
      \ '[^_`[:space:]]\%([^_`]*[^_`[:space:]]\)\?', '_')

" }}}1
