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
      echo printf("%s:%d\n", l:file, l:lnum)

      let l:intro = matchstr(l:msg, '.\{-}\ze\s*\(: \)\?Expected ')
      if !empty(l:intro)
        echo printf("  %s\n", l:intro)
      endif

      let l:expect = matchstr(l:msg, 'Expected \zs.*\zebut got')
      let l:observe = matchstr(l:msg, 'Expected .*but got \zs.*')
      echo printf("  Expected: %s\n", l:expect)
      echo printf("  Observed: %s\n\n", l:observe)
    elseif l:msg =~# 'Pattern.*does\( not\)\? match'
      echo printf("%s:%d\n", l:file, l:lnum)

      let l:intro = matchstr(l:msg, '.\{-}\ze\s*\(: \)\?Pattern ')
      if !empty(l:intro)
        echo printf("  %s\n", l:intro)
      endif

      let l:expect = matchstr(l:msg, 'Pattern.*does\( not\)\? match.*')
      echo printf("  %s\n", l:expect)
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
