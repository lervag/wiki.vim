local M = {}

function M.get_pages()
  -- wiki#page#get_all returns a list of path pairs, where the first element is
  -- the absolute path and the second element is the path relative to wiki
  -- root.
  vim.ui.select(vim.fn["wiki#page#get_all"](), {
    prompt = "WikiPages> ",
    format_item = function(item)
      if item[2]:sub(1, 1) == "/" then
        return item[2]:sub(2)
      else
        return item[2]
      end
    end,
  }, function(item)
    if item then
      vim.cmd.edit(item[1])
    end
  end)
end

function M.get_tags()
  local tags_with_locations = vim.fn["wiki#tags#get_all"]()

  local length = 0
  for tag, _ in pairs(tags_with_locations) do
    if #tag > length then
      length = #tag
    end
  end
  local frmt = "%-" .. length .. "s  %s:%s"

  local root = vim.fn["wiki#get_root"]()
  local items = {}
  for tag, locations in pairs(tags_with_locations) do
    for _, loc in pairs(locations) do
      local path_rel = vim.fn["wiki#paths#relative"](loc[1], root)
      local str = string.format(frmt, tag, path_rel, loc[2])
      table.insert(items, { str, loc[1] })
    end
  end

  vim.ui.select(items, {
    prompt = "WikiTags> ",
    format_item = function(item)
      return item[1]
    end,
  }, function(item)
    if item then
      vim.cmd.edit(item[2])
    end
  end)
end

function M.toc()
  local toc = vim.fn["wiki#toc#gather_entries"]()

  local items = {}
  for _, hd in pairs(toc) do
    local indent = vim.fn["repeat"](".", hd.level - 1)
    local line = hd.lnum .. "|" .. indent .. hd.header
    table.insert(items, line)
  end

  vim.ui.select(items, { prompt = "WikiToc> " }, function(item)
    if item then
      item = vim.split(item, "|")[1]
      vim.cmd.execute(item)
    end
  end)
end

return M
