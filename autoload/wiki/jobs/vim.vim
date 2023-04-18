" A simple wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#jobs#vim#new(cmd) abort " {{{1
  let l:job = deepcopy(s:job)
  let l:job.cmd = has('win32')
        \ ? 'cmd /s /c "' . a:cmd . '"'
        \ : ['sh', '-c', a:cmd]
  return l:job
endfunction

" }}}1
function! wiki#jobs#vim#run(cmd) abort " {{{1
  call s:vim_{s:os}_run(a:cmd)
endfunction

" }}}1
function! wiki#jobs#vim#capture(cmd) abort " {{{1
  return s:vim_{s:os}_capture(a:cmd)
endfunction

" }}}1

function! wiki#jobs#vim#shell_default() abort " {{{1
  let s:saveshell = [
        \ &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash
        \]
  let &shell = 'cmd.exe'
  let &shellcmdflag = '/s /c'
  set shellquote& shellxquote& shellredir& shellslash&
endfunction

" }}}1
function! wiki#jobs#vim#shell_restore() abort " {{{1
  let [   &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash] = s:saveshell
endfunction

" }}}1

let s:os = has('win32') ? 'win' : 'unix'


let s:job = {}

function! s:job.start() abort dict " {{{1
  let l:options = {}

  if self.capture_output
    let self._output = tempname()
    let l:options.out_io = 'file'
    let l:options.err_io = 'file'
    let l:options.out_name = self._output
    let l:options.err_name = self._output
  else
    let l:options.in_io = 'null'
    let l:options.out_io = 'null'
    let l:options.err_io = 'null'
  endif
  if self.detached
    let l:options.stoponexit = ''
  endif
  if !empty(self.cwd)
    let l:options.cwd = self.cwd
  endif

  let self.job = job_start(self.cmd, l:options)

  return self
endfunction

" }}}1
function! s:job.stop() abort dict " {{{1
  call job_stop(self.job)
  for l:dummy in range(25)
    sleep 1m
    if !self.is_running() | return | endif
  endfor
endfunction

" }}}1
function! s:job.wait() abort dict " {{{1
  for l:dummy in range(self.wait_timeout/10)
    sleep 10m
    if !self.is_running() | return | endif
  endfor

  call wiki#log#warn('Job timed out while waiting!', join(self.cmd))
  call self.stop()
endfunction

" }}}1
function! s:job.is_running() abort dict " {{{1
  return job_status(self.job) ==# 'run'
endfunction

" }}}1
function! s:job.get_pid() abort dict " {{{1
  try
    return get(job_info(self.job), 'process')
  catch
    return 0
  endtry
endfunction

" }}}1
function! s:job.signal_hup() abort dict " {{{1
  if self.is_running()
    call job_stop(self.job, 'hup')
  endif
endfunction

" }}}1
function! s:job.output() abort dict " {{{1
  call self.wait()
  return self.capture_output ? readfile(self._output) : []
endfunction

" }}}1


function! s:vim_unix_run(cmd) abort " {{{1
  silent! call system(a:cmd)
endfunction

" }}}1
function! s:vim_unix_capture(cmd) abort " {{{1
  silent! let l:output = systemlist(a:cmd)
  return v:shell_error == 127 ? ['command not found'] : l:output
endfunction

" }}}1

function! s:vim_win_run(cmd) abort " {{{1
  let s:saveshell = [
        \ &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash
        \]
  set shell& shellcmdflag& shellquote& shellxquote& shellredir& shellslash&

  silent! call system('cmd /s /c "' . a:cmd . '"')

  let [   &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash] = s:saveshell
endfunction

" }}}1
function! s:vim_win_capture(cmd) abort " {{{1
  let s:saveshell = [
        \ &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash
        \]
  set shell& shellcmdflag& shellquote& shellxquote& shellredir& shellslash&

  silent! let l:output = systemlist('cmd /s /c "' . a:cmd . '"')

  let [   &shell,
        \ &shellcmdflag,
        \ &shellquote,
        \ &shellxquote,
        \ &shellredir,
        \ &shellslash] = s:saveshell

  return l:output
endfunction

" }}}1

