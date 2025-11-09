vim.opt.runtimepath:prepend "~/.local/plugged/wiki.vim"
vim.opt.runtimepath:prepend "fzf-lua"
vim.cmd [[filetype plugin indent on]]
vim.cmd [[syntax enable]]

vim.keymap.set("n", "q", "<cmd>qall!<cr>")

vim.opt.swapfile = false
vim.opt.more = false

vim.g.wiki_root = vim.fn.fnamemodify("wiki", ":p")
vim.g.wiki_cache_persistent = false
vim.g.wiki_filetypes = { "wiki" }
vim.g.wiki_root = "../wiki-basic"
vim.g.wiki_select_method = {
  pages = require("wiki.fzf_lua").pages,
  tags = require("wiki.fzf_lua").tags,
  toc = require("wiki.fzf_lua").toc,
  links = require("wiki.fzf_lua").links,
}

vim.cmd [[runtime plugin/wiki.vim]]
vim.cmd [[WikiIndex]]

vim.cmd.edit "../wiki-basic/index.wiki"

-- " WikiTags
-- " WikiPages
