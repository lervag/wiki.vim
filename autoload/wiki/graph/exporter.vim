" A wiki plugin for Vim
"
" Maintainer: Karl Yngve Lervåg
" Email:      karl.yngve@gmail.com
"

function! wiki#graph#exporter#run(args) abort " {{{1
  let l:cfg = s:parse_args(a:args)
  if empty(l:cfg) | return | endif

  let l:graph = s:collect(l:cfg)
  if empty(l:graph.nodes)
    return wiki#log#warn('WikiGraphExport: there is nothing to export')
  endif

  call writefile(s:format_{l:cfg.format}(l:graph, l:cfg), l:cfg.fname)

  call wiki#log#info(printf(
        \ 'Graph with %d nodes and %d edges was exported to %s',
        \ len(l:graph.nodes), len(l:graph.edges), l:cfg.fname))

  if l:cfg.view
    call s:view(l:cfg)
  endif

  if l:cfg.edit
    execute 'edit' fnameescape(l:cfg.fname)
  endif
endfunction

" }}}1

let s:formats = {
      \ 'dot': #{ extension: 'dot' },
      \ 'mermaid': #{ extension: 'mmd' },
      \}

" The hierarchical layout of "dot" becomes unreadable for large graphs, so we
" ask for a force directed layout when there are more nodes than this
let s:max_nodes_hierarchical = 50

" The colors that indicate the distance from the origin. The first color is
" for the origin itself and is deliberately different from the rest, which
" fade out with increasing distance. Longer distances use the last color.
let s:distance_colors = [
      \ '#fdae6b',
      \ '#6baed6',
      \ '#9ecae1',
      \ '#c6dbef',
      \ '#deebf7',
      \ '#f7fbff',
      \]
let s:max_distance = len(s:distance_colors) - 1


function! s:parse_args(args) abort " {{{1
  " Parse the command line arguments of WikiGraphExport
  "
  " Return: The export configuration, or an empty dictionary if the arguments
  "         could not be parsed.

  let l:cfg = deepcopy(g:wiki_graph_export)
  let l:cfg.fname = ''
  let l:cfg.depth = 0
  let l:cfg.direction = ''
  let l:cfg.journal = v:true

  for l:arg in a:args
    if l:arg =~# '^--format='
      let l:cfg.format = strpart(l:arg, 9)
    elseif l:arg =~# '^--output='
      let l:cfg.fname = expand(simplify(strpart(l:arg, 9)))
    elseif l:arg =~# '^--depth='
      let l:cfg.depth = strpart(l:arg, 8)
    elseif l:arg ==# '--from'
      let l:cfg.direction = 'out'
    elseif l:arg ==# '--to'
      let l:cfg.direction = 'in'
    elseif l:arg ==# '--both'
      let l:cfg.direction = 'both'
    elseif l:arg ==# '--no-journal'
      let l:cfg.journal = v:false
    elseif l:arg ==# '--color-distance'
      let l:cfg.color_distance = v:true
    elseif l:arg ==# '--open'
      let l:cfg.view = v:true
    elseif l:arg ==# '--edit'
      let l:cfg.edit = v:true
    else
      call wiki#log#error(
            \ 'WikiGraphExport argument "' .. l:arg .. '" not recognized',
            \ 'Please see :help WikiGraphExport')
      return {}
    endif
  endfor

  if !has_key(s:formats, l:cfg.format)
    call wiki#log#error(
          \ 'WikiGraphExport format "' .. l:cfg.format .. '" not recognized',
          \ 'Available formats: ' .. join(sort(keys(s:formats)), ', '))
    return {}
  endif

  if type(l:cfg.depth) == v:t_string
    if l:cfg.depth !~# '^\d\+$'
      call wiki#log#error(
            \ 'WikiGraphExport depth "' .. l:cfg.depth .. '" is not valid',
            \ 'The depth must be a positive number')
      return {}
    endif
    let l:cfg.depth = str2nr(l:cfg.depth)
  endif

  " A depth is only meaningful for a subgraph of the wiki
  if l:cfg.depth > 0 && empty(l:cfg.direction)
    let l:cfg.direction = 'both'
  endif

  " There is no origin to measure the distance from when we export everything
  if l:cfg.color_distance && empty(l:cfg.direction)
    call wiki#log#warn(
          \ 'WikiGraphExport ignores "--color-distance" for the entire wiki',
          \ 'Please combine it with "--from", "--to", "--both" or "--depth"')
    let l:cfg.color_distance = v:false
  endif

  let l:cfg.extension = s:formats[l:cfg.format].extension
  let l:cfg.fname = s:resolve_fname(l:cfg)

  return l:cfg
endfunction

" }}}1
function! s:resolve_fname(cfg) abort " {{{1
  let l:fname = empty(a:cfg.fname) ? a:cfg.output : a:cfg.fname

  " Relative paths are resolved relative to the wiki root
  if !wiki#paths#is_abs(l:fname)
    let l:fname = wiki#get_root() .. '/' .. l:fname
  endif

  " A directory means we should use the default filename
  if l:fname =~# '/$' || isdirectory(l:fname)
    let l:fname ..= '/wiki-graph.' .. a:cfg.extension
  endif
  let l:fname = wiki#paths#s(l:fname)

  let l:dir = fnamemodify(l:fname, ':h')
  if !isdirectory(l:dir)
    call mkdir(l:dir, 'p')
  endif

  return l:fname
endfunction

" }}}1

function! s:collect(cfg) abort " {{{1
  " Gather the part of the wiki graph that should be exported
  "
  " Return: A dictionary with the following keys:
  "   nodes: dictionary of absolute path -> node (see s:new_node)
  "   edges: list of dictionaries with the keys "from", "to" and "weight",
  "          where "from" and "to" are absolute paths

  let l:graph = wiki#graph#builder#get()

  " Fully refresh the cache - this takes some extra time, but it ensures that
  " the exported graph is up to date.
  call l:graph.refresh_cache(#{force: v:true})

  " Notice that the filter is applied during the traversal below, so that
  " excluded files do not act as bridges between the included ones
  let l:Filter = a:cfg.journal
        \ ? { _ -> v:true }
        \ : { x -> !wiki#journal#is_in_journal(x) }

  " When we export a subgraph, then the current page is the origin and we know
  " the distance from it to each of the other pages. There is no origin when
  " the entire wiki is exported.
  if empty(a:cfg.direction)
    let l:origin = ''
    let l:distances = {}
    let l:files = filter(l:graph.get_files(), { _, x -> l:Filter(x) })
  else
    let l:origin = expand('%:p')
    let l:distances = l:graph.get_neighbourhood(
          \ l:origin, a:cfg.depth, a:cfg.direction, l:Filter)
    let l:files = keys(l:distances)
  endif

  " Sort the files to get a deterministic output
  call sort(l:files)

  let l:root = wiki#get_root()
  let l:nodes = {}
  for l:file in l:files
    let l:nodes[l:file] = s:new_node(l:file, l:root)
    let l:nodes[l:file].distance = get(l:distances, l:file, -1)
    let l:nodes[l:file].origin = !empty(l:origin) && l:file ==# l:origin
  endfor

  " Collect the edges between the included files. Links to files that are not
  " included are dropped, except for broken links, which are useful to see.
  "
  " All the links between a pair of files are combined into a single edge,
  " where the weight is the total number of links and where "bidirectional"
  " tells whether the two files link to each other.
  let l:edges = []
  let l:index = {}
  for l:file in l:files
    for l:link in l:graph.get_links_from(l:file)
      let l:target = l:link.filename_to

      if !has_key(l:nodes, l:target)
        if filereadable(l:target) || !l:Filter(l:target) | continue | endif

        let l:nodes[l:target] = s:new_node(l:target, l:root)
      endif

      let l:key = l:file .. '|' .. l:target
      if has_key(l:index, l:key)
        let l:index[l:key].weight += 1
        continue
      endif

      " Reuse the edge in the opposite direction if there is one. Notice that
      " we index it both ways, so that later links find it as well.
      let l:reverse = l:target .. '|' .. l:file
      if has_key(l:index, l:reverse)
        let l:index[l:reverse].weight += 1
        let l:index[l:reverse].bidirectional = v:true
        let l:index[l:key] = l:index[l:reverse]
      else
        let l:index[l:key] = #{
              \ from: l:file,
              \ to: l:target,
              \ weight: 1,
              \ bidirectional: v:false,
              \}
        call add(l:edges, l:index[l:key])
      endif

      let l:nodes[l:file].n_out += 1
      let l:nodes[l:target].n_in += 1
    endfor
  endfor

  return #{ nodes: l:nodes, edges: l:edges }
endfunction

" }}}1
function! s:new_node(file, root) abort " {{{1
  " The id is the path relative to the wiki root, which is unique and more
  " readable than the absolute path. The name is the node name, which is also
  " used elsewhere for displaying wiki files, see wiki#paths#to_node.
  "
  " A distance of -1 means the distance from the origin is not known, which is
  " the case both when the entire wiki is exported and for broken links that
  " are outside the exported neighbourhood.
  return {
        \ 'id': wiki#paths#relative(a:file, a:root),
        \ 'name': wiki#paths#to_node(a:file),
        \ 'broken': !filereadable(a:file),
        \ 'journal': wiki#journal#is_in_journal(a:file),
        \ 'distance': -1,
        \ 'origin': v:false,
        \ 'n_in': 0,
        \ 'n_out': 0,
        \}
endfunction

" }}}1

function! s:format_dot(graph, cfg) abort " {{{1
  let l:files = sort(keys(a:graph.nodes))

  let l:lines = [
        \ '// Generated by wiki.vim on ' .. strftime('%Y-%m-%d %H:%M'),
        \ 'digraph wiki {',
        \ '  graph [' .. (len(l:files) > s:max_nodes_hierarchical
        \   ? 'layout="sfdp", overlap="prism", K=0.6'
        \   : 'layout="dot", rankdir="LR"') .. '];',
        \ '  node [shape="box", style="rounded", fontname="sans-serif"];',
        \ '  edge [color="#666666"];',
        \ '',
        \]

  for l:file in l:files
    let l:node = a:graph.nodes[l:file]

    let l:attrs = [
          \ printf('label="%s"', s:escape_dot(l:node.name)),
          \ printf('URL="file://%s"', s:escape_dot(l:file)),
          \]
    if l:node.broken
      call add(l:attrs, 'tooltip="Broken link"')
      call add(l:attrs, 'color="#cc0000"')
      call add(l:attrs, 'style="rounded,dashed"')
    else
      call add(l:attrs, printf('tooltip="%s"', s:tooltip(l:node)))

      if l:node.origin
        call add(l:attrs, 'style="rounded,filled,bold"')
        call add(l:attrs, printf('fillcolor="%s"', s:distance_color(0)))
        call add(l:attrs, 'penwidth=2')
      elseif a:cfg.color_distance && l:node.distance > 0
        call add(l:attrs, 'style="rounded,filled"')
        call add(l:attrs,
              \ printf('fillcolor="%s"', s:distance_color(l:node.distance)))
      elseif l:node.journal
        call add(l:attrs, 'color="#999999"')
      endif
    endif

    call add(l:lines, printf('  "%s" [%s];',
          \ s:escape_dot(l:node.id), join(l:attrs, ', ')))
  endfor

  call add(l:lines, '')

  for l:edge in a:graph.edges
    let l:attrs = []
    if l:edge.bidirectional
      call add(l:attrs, 'dir="both"')
    endif
    if l:edge.weight > 1
      call add(l:attrs, printf('label="%d"', l:edge.weight))
      call add(l:attrs, printf('penwidth=%d', min([l:edge.weight, 4])))
    endif

    call add(l:lines, printf('  "%s" -> "%s"%s;',
          \ s:escape_dot(a:graph.nodes[l:edge.from].id),
          \ s:escape_dot(a:graph.nodes[l:edge.to].id),
          \ empty(l:attrs) ? '' : ' [' .. join(l:attrs, ', ') .. ']'))
  endfor

  return l:lines + ['}']
endfunction

" }}}1
function! s:format_mermaid(graph, cfg) abort " {{{1
  let l:files = sort(keys(a:graph.nodes))

  " Mermaid requires simple node ids, so we enumerate the nodes
  let l:ids = {}
  for l:i in range(len(l:files))
    let l:ids[l:files[l:i]] = 'n' .. l:i
  endfor

  let l:lines = [
        \ '%% Generated by wiki.vim on ' .. strftime('%Y-%m-%d %H:%M'),
        \ 'graph LR',
        \]

  " Mermaid styles are applied through classes, so we group the nodes by the
  " class they should be assigned
  let l:classes = {}
  for l:file in l:files
    let l:node = a:graph.nodes[l:file]
    call add(l:lines, printf('  %s["%s"]',
          \ l:ids[l:file], s:escape_mermaid(l:node.name)))

    let l:class = l:node.broken
          \ ? 'broken'
          \ : l:node.origin
          \   ? 'origin'
          \   : a:cfg.color_distance && l:node.distance > 0
          \     ? 'distance' .. min([l:node.distance, s:max_distance])
          \     : ''
    if empty(l:class) | continue | endif

    if !has_key(l:classes, l:class)
      let l:classes[l:class] = []
    endif
    call add(l:classes[l:class], l:ids[l:file])
  endfor

  for l:edge in a:graph.edges
    call add(l:lines, printf('  %s %s%s %s',
          \ l:ids[l:edge.from],
          \ l:edge.bidirectional ? '<-->' : '-->',
          \ l:edge.weight > 1 ? printf('|%d|', l:edge.weight) : '',
          \ l:ids[l:edge.to]))
  endfor

  for l:class in sort(keys(l:classes))
    call add(l:lines, printf('  classDef %s %s;', l:class,
          \ l:class ==# 'broken'
          \   ? 'stroke:#cc0000,stroke-dasharray:4'
          \   : l:class ==# 'origin'
          \     ? printf('fill:%s,stroke-width:3px', s:distance_color(0))
          \     : printf('fill:%s',
          \              s:distance_color(str2nr(l:class[8:])))))
    call add(l:lines, printf('  class %s %s;',
          \ join(l:classes[l:class], ','), l:class))
  endfor

  return l:lines
endfunction

" }}}1
function! s:distance_color(distance) abort " {{{1
  return s:distance_colors[min([a:distance, s:max_distance])]
endfunction

" }}}1
function! s:tooltip(node) abort " {{{1
  let l:tooltip = printf('%d incoming, %d outgoing', a:node.n_in, a:node.n_out)

  if a:node.origin
    return l:tooltip .. ' (origin)'
  endif

  return a:node.distance >= 0
        \ ? printf('%s (distance %d)', l:tooltip, a:node.distance)
        \ : l:tooltip
endfunction

" }}}1
function! s:escape_dot(string) abort " {{{1
  return escape(a:string, '\"')
endfunction

" }}}1
function! s:escape_mermaid(string) abort " {{{1
  return substitute(a:string, '"', '#quot;', 'g')
endfunction

" }}}1

function! s:view(cfg) abort " {{{1
  " Render the exported graph and open the result in the relevant viewer. If
  " no renderer is available, we simply open the exported file itself.

  let l:renderer = get(a:cfg.renderer, a:cfg.format, '')
  let l:executable = empty(l:renderer) ? '' : split(l:renderer)[0]

  if empty(l:executable) || !executable(l:executable)
    call wiki#log#warn(
          \ empty(l:executable)
          \   ? 'WikiGraphExport has no renderer for format: ' .. a:cfg.format
          \   : 'WikiGraphExport renderer is not executable: ' .. l:executable,
          \ 'Opening the exported file instead')
    execute 'edit' fnameescape(a:cfg.fname)
    return
  endif

  let l:rendered = a:cfg.fname .. '.svg'
  let l:cmd = substitute(l:renderer, '{input}\|{output}',
        \ { m -> escape(wiki#u#shellescape(
        \     m[0] ==# '{input}' ? a:cfg.fname : l:rendered), '\&~') },
        \ 'g')

  let l:output = wiki#jobs#capture(l:cmd)
  if v:shell_error > 0
    return wiki#log#error(
          \ 'Something went wrong when running cmd:', l:cmd,
          \ 'Shell output:', join(l:output, "\n"))
  endif

  if !filereadable(l:rendered)
    return wiki#log#error(
          \ 'WikiGraphExport could not find the rendered graph: ' .. l:rendered)
  endif

  call wiki#log#info('Graph was rendered to ' .. l:rendered)
  call call(has('nvim') ? 'jobstart' : 'job_start',
        \ [[get(g:wiki_viewer, 'svg', g:wiki_viewer['_']), l:rendered]])
endfunction

" }}}1
