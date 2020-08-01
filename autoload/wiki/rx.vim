" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
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

let wiki#rx#word = '[^[:blank:]!"$%&''()*+,:;<=>?\[\]\\^`{}]\+'
let wiki#rx#pre_beg = '^\s*```'
let wiki#rx#pre_end = '^\s*```\s*$'
let wiki#rx#super = '\^[^^`]\+\^'
let wiki#rx#sub = ',,[^,`]\+,,'
let wiki#rx#list_define = '::\%(\s\|$\)'
let wiki#rx#comment = '^\s*%%.*$'
let wiki#rx#todo = '\C\<\%(TODO\|STARTED\|FIXME\)\>:\?'
let wiki#rx#done = '\C\<\%(OK\|DONE\|FIXED\)\>:\?'
let wiki#rx#header = '^#\{1,6}\s*[^#].*'
let wiki#rx#header_items = '^\(#\{1,6}\)\s*\([^#].*\)\s*$'
let wiki#rx#bold = wiki#rx#surrounded(
      \ '[^*`[:space:]]\%([^*`]*[^*`[:space:]]\)\?', '*')
let wiki#rx#italic = wiki#rx#surrounded(
      \ '[^_`[:space:]]\%([^_`]*[^_`[:space:]]\)\?', '_')
