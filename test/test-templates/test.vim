source ../init.vim

function! TemplateB(context) abort " {{{1
  call append(0, [
        \ 'Hello from TemplateB function!',
        \ a:context.name,
        \ a:context.path_wiki,
        \])
endfunction

" }}}1
let g:wiki_root = g:testroot . '/wiki-basic'
let g:wiki_templates = [
      \ {
      \   'match_re': '^Template A',
      \   'source_filename': g:testroot . '/test-templates/template-a.md'
      \ },
      \ {
      \   'match_re': '^Template B',
      \   'source_func': function('TemplateB')
      \ },
      \ {
      \   'match_func': {_ -> v:true},
      \   'source_func': {_ -> append(0, ['Fallback'])}
      \ },
      \]

runtime plugin/wiki.vim

silent call wiki#page#open('Template B')
call assert_equal([
      \ 'Hello from TemplateB function!',
      \ 'Template B',
      \ 'Template B.wiki',
      \], getline(1, line('$') - 1))

bwipeout
silent call wiki#page#open('Template C')
call assert_equal('Fallback', getline(1))

call wiki#test#finished()
