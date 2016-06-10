" vimwiki
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! vimwiki#complete#omnicomplete(findstart, base) " {{{1
  if a:findstart == 1
    let column = col('.')-2
    let line = getline('.')[:column]
    let startoflink = match(line, '\[\[\zs[^\\[\]]*$')
    if startoflink != -1
      let s:line_context = '['
      return startoflink
    endif

    " markdown
    let startofinlinelink = match(line, '\[.*\](\zs[^)]*$')
    if startofinlinelink != -1
      let s:line_context = '['
      return startofinlinelink
    endif

    let s:line_context = ''
    return -1
  else
    " Completion works for wikilinks/anchors, and for tags. s:line_content
    " tells us, which string came before a:base. There seems to be no easier
    " solution, because calling col('.') here returns garbage.
    if s:line_context == ''
      return []
    elseif a:base !~# '#'
      " we look for wiki files

      if a:base =~# '^wiki\d:'
        let wikinumber = eval(matchstr(a:base, '^wiki\zs\d'))
        if wikinumber >= 1
          return []
        endif
        let prefix = matchstr(a:base, '^wiki\d:\zs.*')
        let scheme = matchstr(a:base, '^wiki\d:\ze')
      elseif a:base =~# '^diary:'
        let wikinumber = -1
        let prefix = matchstr(a:base, '^diary:\zs.*')
        let scheme = matchstr(a:base, '^diary:\ze')
      else " current wiki
        let wikinumber = 0
        let prefix = a:base
        let scheme = ''
      endif

      let links = vimwiki#base#get_wikilinks(wikinumber, 1)
      let result = []
      for wikifile in links
        if wikifile =~ '^'.vimwiki#u#escape(prefix)
          call add(result, scheme . wikifile)
        endif
      endfor
      return result

    else
      " we look for anchors in the given wikifile

      let segments = split(a:base, '#', 1)
      let given_wikifile = segments[0] == '' ? expand('%:t:r') : segments[0]
      let link_infos = vimwiki#link#resolve(given_wikifile.'#')
      let wikifile = link_infos.filename
      let syntax = 'markdown'
      let anchors = vimwiki#base#get_anchors(wikifile, syntax)

      let filtered_anchors = []
      let given_anchor = join(segments[1:], '#')
      for anchor in anchors
        if anchor =~# '^'.vimwiki#u#escape(given_anchor)
          call add(filtered_anchors, segments[0].'#'.anchor)
        endif
      endfor
      return filtered_anchors

    endif
  endif
endfunction

" }}}1

" vim: fdm=marker sw=2
