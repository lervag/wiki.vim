" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#scratch#new(opts) abort " {{{1
  let l:buf = extend(deepcopy(s:scratch), a:opts)
  call l:buf.open()
endfunction

" }}}1


let s:scratch = {
      \ 'name' : 'WikiScratch'
      \}
function! s:scratch.open() abort dict " {{{1
  let l:bufnr = bufnr('')
  let l:wiki = get(b:, 'wiki', {})

  silent execute 'keepalt edit' escape(self.name, ' ')

  call wiki#buffer#init()

  let self.prev_bufnr = l:bufnr
  let b:scratch = self
  let b:wiki = l:wiki

  setlocal bufhidden=wipe
  setlocal buftype=nofile
  setlocal concealcursor=nvic
  setlocal conceallevel=0
  setlocal nobuflisted
  setlocal nolist
  setlocal nospell
  setlocal noswapfile
  setlocal nowrap
  setlocal tabstop=8

  nnoremap <silent><nowait><buffer> q     :call b:scratch.close()<cr>
  nnoremap <silent><nowait><buffer> <esc> :call b:scratch.close()<cr>
  nnoremap <silent><nowait><buffer> <c-6> :call b:scratch.close()<cr>
  nnoremap <silent><nowait><buffer> <c-^> :call b:scratch.close()<cr>
  nnoremap <silent><nowait><buffer> <c-e> :call b:scratch.close()<cr>

  if has_key(self, 'syntax')
    call self.syntax()
  endif

  if has_key(self, 'post_init')
    call self.post_init()
  endif

  call self.fill()
endfunction

" }}}1
function! s:scratch.close() abort dict " {{{1
  silent execute 'keepalt buffer' self.prev_bufnr
endfunction

" }}}1
function! s:scratch.fill() abort dict " {{{1
  setlocal modifiable
  %delete

  call self.print_content()

  0delete _
  setlocal nomodifiable
endfunction

" }}}1
