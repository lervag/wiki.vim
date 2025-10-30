local fzf = require "fzf-lua"
local fzf_data = require "fzf-lua".config.__resume_data

local M = {}

M.pages = function()
  fzf.files({
    prompt = "Wiki files>",
    cwd = vim.g.wiki_root,
    actions = {
      ['default'] = function(selected)
        local note = selected[1]
        if not note then
          if fzf_data.last_query then
            note = fzf_data.last_query
          end
        end
        vim.fn["wiki#page#open"](note)
      end,
    }
  })
end

M.tags = function()
  local tags_with_locations = vim.fn["wiki#tags#get_all"]()
  local root = vim.fn["wiki#get_root"]()
  local items = {}
  for tag, locations in pairs(tags_with_locations) do
    for _, loc in pairs(locations) do
      local path = vim.fn["wiki#paths#relative"](loc[1], root)
      local str = string.format("%s:%d:%s", tag, loc[2], path)
      table.insert(items, str)
    end
  end
  fzf.fzf_exec(items, {
    actions = {
      ['default'] = function(selected)
        local note = vim.split(selected[1], ':')[3]
        if note then
          vim.fn["wiki#page#open"](note)
        end
      end
    }
  })
end

M.toc = function()
  local toc = vim.fn["wiki#toc#gather_entries"]()
  local items = {}
  for _, hd in pairs(toc) do
    local indent = vim.fn["repeat"](".", hd.level - 1)
    local line = indent .. hd.header
    table.insert(items, string.format("%d:%s", hd.lnum, line))
  end
  fzf.fzf_exec(items, {
    actions = {
      ['default'] = function(selected)
        local ln = vim.split(selected[1], ':')[1]
        if ln then
          vim.fn.execute(ln)
        end
      end
    }
  })
end

---Select a wiki page and insert a link to it
---@param mode? "visual" | "insert"
M.links = function(mode)
  local text = ""
  if mode == "visual" then
    vim.cmd [[normal! "wd]]
    text = vim.fn.trim(vim.fn.getreg "w")
  end

  fzf.files({
    prompt = "Add wiki link>",
    cwd = vim.g.wiki_root,
    actions = {
      ["default"] = function(selected)
        local note = selected[1]
        if not note then
          if fzf_data.last_query then
            note = fzf_data.last_query
          end
        end
        note = vim.g.wiki_root .. note
        vim.fn["wiki#link#add"](note, "", { text = text })
      end,
    },
  })
end

return M
