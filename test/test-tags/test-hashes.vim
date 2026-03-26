source ../init.vim
runtime plugin/wiki.vim

let g:wiki_log_verbose = 0
let g:wiki_filetypes = ['wiki']

let s:tag_parser = deepcopy(g:wiki#tags#default_parser)
let s:tag_parser.re_match = '\v%(^|\s)#\zs[^# ]+'
let s:tag_parser.re_findstart = '\v%(^|\s)#\zs[^# ]+'
let s:tag_parser.re_parse = '\v#\zs[^# ]+'
let s:tag_parser.make = {t, l -> empty(t) ? '' : join(map(t, '"#" . v:val'))}
let g:wiki_tag_parsers = [s:tag_parser]

silent edit wiki-tmp/index.wiki

let s:tags = wiki#tags#get_all()
call assert_equal(['tagged'], sort(keys(s:tags)))


call wiki#test#finished()
