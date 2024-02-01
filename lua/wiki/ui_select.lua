local M = {}

---Format a page item for display in vim.ui.select
---@param item table
---@return string
local function format_page_item(item)
  if item[2]:sub(1, 1) == "/" then
    return item[2]:sub(2)
  else
    return item[2]
  end
end

function M.pages()
  vim.ui.select(vim.fn["wiki#page#get_all"](), {
    prompt = "WikiPages> ",
    format_item = format_page_item,
  }, function(item)
    if item then
      vim.cmd.edit(item[1])
    end
  end)
end

function M.tags()
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

---Select a wiki page and insert a link to it
---@param insert_mode boolean True if function is called from insert mode
function M.links(insert_mode)
  vim.ui.select(vim.fn["wiki#page#get_all"](), {
    prompt = "WikiLinkAdd> ",
    format_item = format_page_item,
  }, function(item)
    if item then
      local root = vim.fn["wiki#get_root"]()
      local url = vim.fn["wiki#paths#to_wiki_url"](item[1], root)

      local col_cursor = vim.fn.col "."
      local col_end = vim.fn.col "$"
      local cursor_at_end = col_cursor + 1 >= col_end

      vim.fn["wiki#link#add"](url)

      if insert_mode then
        if cursor_at_end then
          vim.cmd "startinsert!"
        else
          vim.cmd "startinsert"
        end
      end
    end
  end)
end

return M
