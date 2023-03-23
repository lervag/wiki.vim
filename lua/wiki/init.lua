local M = {}

-- Returns shorten path
local function filter(path)
  local root = vim.g.wiki_root .. "/"
  return path:gsub(root, "")
end

-- Returns full path
local function unfilter(path)
  local root = vim.g.wiki_root .. "/"
  return root .. path
end

function M.get_pages()
  local res = {}
  local pages = vim.fn["wiki#page#get_all"]()
  for _, p in pairs(pages) do
    local page = filter(p[1])
    table.insert(res, page)
  end
  vim.ui.select(res, { prompt = "WikiPages> " }, function(f)
    f = unfilter(f)
    vim.cmd("edit " .. f)
  end)
end

function M.get_tags()
  local res = {}
  local tags = vim.fn["wiki#tags#get_all"]()
  for key, val in pairs(tags) do
    for _, file in pairs(val) do
      local str = string.format("%s:%s:%s", key, file[2], filter(file[1]))
      table.insert(res, str)
    end
  end
  vim.ui.select(res, { prompt = "WikiTags> " }, function(t)
    t = unfilter(vim.split(t, ":")[3])
    vim.cmd("edit " .. t)
  end)
  return res
end

function M.toc()
  local res = {}
  local toc = vim.fn["wiki#toc#gather_entries"]()
  for _, hd in pairs(toc) do
    local indent = vim.fn["repeat"](".", hd.level - 1)
    local line = hd.lnum .. "|" .. indent .. hd.header
    table.insert(res, line)
  end
  vim.ui.select(res, { prompt = "WikiToc> " }, function(t)
    t = vim.split(t, "|")[1]
    vim.cmd("execute " .. t)
  end)
end

return M
