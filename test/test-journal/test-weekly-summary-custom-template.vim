source ../init.vim

" This tests the "fully custom scaffold" weekly summary template documented in
" |wiki-advanced-config-5|. Unlike the built-in summary, it reads each daily
" entry verbatim and thus keeps content after the first section header.

let s:root = tempname()
let g:wiki_root = s:root
let g:wiki_journal = {'root': s:root}
runtime plugin/wiki.vim

" Register the documented custom template (see wiki-advanced-config-5)
lua << EOF
vim.g.wiki_templates = {
  {
    match_re = [[\d\d\d\d_w\d\d]],
    source_func = function(ctx)
      local year, week = ctx.name:match "(%d%d%d%d)_w(%d%d)"

      local lines = {
        "# Summary, " .. year .. " week " .. week,
        "",
        "## Highlights",
        "",
        "## Goals for next week",
        "",
        "## Journal entries",
      }

      for _, date in ipairs(vim.fn["wiki#date#get_week_dates"](week, year)) do
        local url = vim.fn["wiki#url#resolve"]("journal:" .. date)
        if vim.fn.filereadable(url.path) == 1 then
          table.insert(lines, "")
          table.insert(lines, "### " .. date)
          table.insert(lines, "")
          vim.list_extend(lines, vim.fn.readfile(url.path))
        end
      end

      vim.fn.append(0, lines)
    end,
  },
}
EOF

let s:dates = wiki#date#get_week_dates(2, 2019)
call mkdir(s:root, 'p')

" Monday: contains a section header - its content must NOT be dropped
call writefile([
      \ 'Project 1',
      \ '* did this',
      \ '',
      \ '# Meeting notes',
      \ '* secret plans',
      \], s:root . '/' . s:dates[0] . '.wiki')

" Tuesday: simple entry
call writefile([
      \ 'Project 1',
      \ '* did more',
      \], s:root . '/' . s:dates[1] . '.wiki')

" Opening the weekly node triggers the custom template
silent call wiki#journal#open('2019_w02')
let s:lines = getline(1, '$')

" The custom scaffold is present
call assert_equal('# Summary, 2019 week 02', s:lines[0])
call assert_notequal(-1, index(s:lines, '## Highlights'))
call assert_notequal(-1, index(s:lines, '## Goals for next week'))
call assert_notequal(-1, index(s:lines, '## Journal entries'))

" Each existing daily entry gets a dated sub-header
call assert_notequal(-1, index(s:lines, '### ' . s:dates[0]))
call assert_notequal(-1, index(s:lines, '### ' . s:dates[1]))

" The daily entries are included verbatim ...
call assert_notequal(-1, index(s:lines, '* did this'))
call assert_notequal(-1, index(s:lines, '* did more'))

" ... including content after the first section header, which the built-in
" summary would have dropped
call assert_notequal(-1, index(s:lines, '# Meeting notes'))
call assert_notequal(-1, index(s:lines, '* secret plans'))

" Missing days for the week are simply skipped (only two entries were created)
call assert_equal(-1, index(s:lines, '### ' . s:dates[2]))

bwipeout!
call wiki#test#finished()
