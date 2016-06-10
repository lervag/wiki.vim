" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#markdown_base#reset_mkd_refs() "{{{1
  if has_key(get(b:, 'vimwiki_list', {}), 'markdown_refs')
    call remove(b:vimwiki_list, 'markdown_refs')
  endif
endfunction

"}}}1
function! vimwiki#markdown_base#scan_reflinks() " {{{
  let mkd_refs = {}
  " construct list of references using vimgrep
  try
    " Why noautocmd? Because https://github.com/vimwiki/vimwiki/issues/121
    noautocmd execute 'vimgrep #'.g:vimwiki_rxMkdRef.'#j %'
  catch /^Vim\%((\a\+)\)\=:E480/   " No Match
    "Ignore it, and move on to the next file
  endtry
  " 
  for d in getqflist()
    let matchline = join(getline(d.lnum, min([d.lnum+1, line('$')])), ' ')
    let descr = matchstr(matchline, g:vimwiki_rxMkdRefMatchDescr)
    let url = matchstr(matchline, g:vimwiki_rxMkdRefMatchUrl)
    if descr != '' && url != ''
      let mkd_refs[descr] = url
    endif
  endfor
  call vimwiki#opts#set('markdown_refs', mkd_refs)
  return mkd_refs
endfunction "}}}
function! vimwiki#markdown_base#get_reflinks() " {{{
  let done = 1
  try
    let mkd_refs = vimwiki#opts#get('markdown_refs')
  catch
    " work-around hack
    let done = 0
    " ... the following command does not work inside catch block !?
    " > let mkd_refs = vimwiki#markdown_base#scan_reflinks()
  endtry
  if !done
    let mkd_refs = vimwiki#markdown_base#scan_reflinks()
  endif
  return mkd_refs
endfunction "}}}
function! vimwiki#markdown_base#open_reflink(link) " {{{
  " echom "vimwiki#markdown_base#open_reflink"
  let link = a:link
  let mkd_refs = vimwiki#markdown_base#get_reflinks()
  if has_key(mkd_refs, link)
    let url = mkd_refs[link]
    call vimwiki#base#system_open_link(url)
    return 1
  else
    return 0
  endif
endfunction " }}}

" vim: fdm=marker sw=2
