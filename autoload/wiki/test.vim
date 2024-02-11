" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#test#finished() abort " {{{1
  for l:error in v:errors
    let l:match = matchlist(l:error, '\(.*\) line \(\d\+\): \(.*\)')
    let l:file = fnamemodify(l:match[1], ':.')
    let l:lnum = l:match[2]
    let l:msg = l:match[3]

    if l:msg =~# 'Expected .*but got'
      call s:print_expected_but_got(l:file, l:lnum, l:msg)
    elseif l:msg =~# 'Pattern.*does\( not\)\? match'
      call s:print_pattern_does_not_match(l:file, l:lnum, l:msg)
    else
      echo printf("%s:%d: %s\n", l:file, l:lnum, l:msg)
    endif
  endfor

  if $QUIT
    if len(v:errors) > 0
      cquit
    else
      quitall!
    endif
  endif
endfunction

" }}}1
function! wiki#test#completion(context, ...) abort " {{{1
  let l:base = a:0 > 0 ? a:1 : ''

  try
    silent execute 'normal GO' . a:context . "\<c-x>\<c-o>"
    silent normal! u
    return wiki#complete#omnicomplete(0, l:base)
  catch
    call assert_report(
          \ printf("\n  Context: %s\n  Base: %s\n%s",
          \        a:context, l:base, v:exception))
  endtry
endfunction

" }}}1

function! s:print_expected_but_got(file, lnum, msg) abort " {{{1
  echo printf("%s:%d\n", a:file, a:lnum)

  let l:intro = matchstr(a:msg, '.\{-}\ze\s*\(: \)\?Expected ')
  if !empty(l:intro)
    echo printf("  %s\n", l:intro)
  endif

  call s:print_msg_with_title(
        \ 'Expected', matchstr(a:msg, 'Expected \zs.*\zebut got'))
  call s:print_msg_with_title(
        \ 'Observed', matchstr(a:msg, 'Expected .*but got \zs.*'))

  echo ''
endfunction

" }}}1
function! s:print_pattern_does_not_match(file, lnum, msg) abort " {{{1
  echo printf("%s:%d\n", a:file, a:lnum)

  let l:intro = matchstr(a:msg, '.\{-}\ze\s*\(: \)\?Pattern ')
  if !empty(l:intro)
    echo printf("  %s\n", l:intro)
  endif

  let l:expect = matchstr(a:msg, 'Pattern.*does\( not\)\? match.*')
  echo printf("  %s\n", l:expect)
endfunction

" }}}1
function! s:print_msg_with_title(title, msg) abort " {{{1
  if a:msg[0] ==# '['
    echo printf("  %s:", a:title)
    for l:line in json_decode(substitute(escape(a:msg, '"'), "'", '"', 'g'))
      echo '   |' .. l:line
    endfor
  else
    echo printf("  %s: %s\n", a:title, a:msg)
  endif
endfunction

" }}}1
