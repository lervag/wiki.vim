vim.opt.runtimepath:prepend "~/.local/plugged/wiki.vim"
vim.opt.runtimepath:prepend "~/.local/plugged/telescope.nvim"
vim.opt.runtimepath:prepend "~/.local/plugged/plenary.nvim"
vim.cmd [[filetype plugin indent on]]
vim.cmd [[syntax enable]]

vim.keymap.set("n", "q", "<cmd>qall!<cr>")

vim.opt.swapfile = false
vim.opt.more = false

vim.g.wiki_root = vim.fn.fnamemodify("wiki", ':p')
vim.g.wiki_cache_root = "."
vim.g.wiki_cache_persistent = false
vim.g.wiki_filetypes = {"wiki"}
vim.g.wiki_root = "../wiki-basic"
vim.g.wiki_select_method = {
  pages = require("wiki.telescope").pages,
  tags = require("wiki.telescope").tags,
  toc = require("wiki.telescope").toc,
  links = require("wiki.telescope").links,
}

vim.cmd [[runtime plugin/wiki.vim]]
vim.cmd [[WikiIndex]]

vim.cmd.edit "../wiki-basic/index.wiki"

-- " WikiTags
-- " WikiPages
