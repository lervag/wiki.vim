" A wiki plugin for Vim -- test stub
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"
" Select this with `let g:wiki_ui_method.input = 'test'` to answer input
" prompts from a prepared list instead of asking the user. This is necessary
" because the prompt of input() is echoed even under `silent` and `redir`,
" which would pollute the output of the test suite.
"

function! wiki#ui#test#input(options) abort " {{{1
  return get(g:, 'wiki_test_input', '')
endfunction

" }}}1
