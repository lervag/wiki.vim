local conf = require("telescope.config").values
local pickers = require "telescope.pickers"
local finders = require "telescope.finders"
local builtin = require "telescope.builtin"
local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local M = {}

function M.pages(opts)
  builtin.find_files(vim.tbl_deep_extend("force", {
    prompt_title = "Wiki files",
    cwd = vim.fn["wiki#get_root"](),
    file_ignore_patterns = {
      "%.stversions/",
      "%.git/",
    },
    path_display = function(_, path)
      local name = path:match "(.+)%.[^.]+$"
      return name or path
    end,
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace_if(function()
        return action_state.get_selected_entry() == nil
      end, function()
        actions.close(prompt_bufnr)
        local new_name = action_state.get_current_line()
        if vim.fn.empty(new_name) ~= 1 then
          return
        end
        vim.fn["wiki#page#open"](new_name)
      end)
      return true
    end,
  }, opts or {}))
end

function M.tags(opts)
  local tags_with_locations = vim.fn["wiki#tags#get_all"]()

  local length = 0
  for tag, _ in pairs(tags_with_locations) do
    if #tag > length then
      length = #tag
    end
  end

  local root = vim.fn["wiki#get_root"]()
  local items = {}
  for tag, locations in pairs(tags_with_locations) do
    for _, loc in pairs(locations) do
      local path_rel = vim.fn["wiki#paths#relative"](loc[1], root)
      local str =
        string.format("%-" .. length .. "s  %s:%s", tag, path_rel, loc[2])
      table.insert(items, { str, loc[1], loc[2] })
    end
  end

  opts = opts or {}

  local telescope_opts = vim.tbl_deep_extend("force", {
    prompt_title = "Wiki Tags",
    sorter = conf.generic_sorter(opts),
    previewer = conf.grep_previewer(opts),
  }, opts)

  pickers
    .new(telescope_opts, {
      finder = finders.new_table {
        results = items,
        entry_maker = function(entry)
          return {
            value = entry[2],
            display = entry[1],
            ordinal = entry[1],
            lnum = entry[3],
          }
        end,
      },
    })
    :find()
end

function M.toc(opts)
  local toc = vim.fn["wiki#toc#gather_entries"]()

  local items = {}
  for _, hd in pairs(toc) do
    local indent = vim.fn["repeat"](".", hd.level - 1)
    local line = indent .. hd.header
    table.insert(items, { line, hd.lnum })
  end

  opts = opts or {}

  local telescope_opts = vim.tbl_deep_extend("force", {
    prompt_title = "Wiki Toc",
    sorter = conf.generic_sorter(opts),
    previewer = false,
    attach_mappings = function(prompt_buf, _)
      actions.select_default:replace(function()
        actions.close(prompt_buf)
        local entry = action_state.get_selected_entry()
        vim.cmd.execute(entry.lnum)
      end)

      return true
    end,
  }, opts)

  pickers
    .new(telescope_opts, {
      finder = finders.new_table {
        results = items,
        entry_maker = function(entry)
          return {
            display = entry[1],
            ordinal = entry[1],
            value = entry[1],
            lnum = entry[2],
          }
        end,
      },
    })
    :find()
end

---Select a wiki page and insert a link to it
---@param insert_mode boolean True if function is called from insert mode
---@param opts table User options for telescope
function M.links(insert_mode, opts)
  builtin.find_files(vim.tbl_deep_extend("force", {
    prompt_title = "Add wiki link",
    cwd = vim.fn["wiki#get_root"](),
    file_ignore_patterns = {
      "%.stversions/",
      "%.git/",
    },
    path_display = function(_, path)
      local name = path:match "(.+)%.[^.]+$"
      return name or path
    end,
    attach_mappings = function(prompt_bufnr, _)
      actions.select_default:replace(function()
        actions.close(prompt_bufnr)

        local path = ""
        local entry = action_state.get_selected_entry()
        if entry then
          path = entry.path
        else
          path = action_state.get_current_line()
        end

        local col_cursor = vim.fn.col "."
        local col_end = vim.fn.col "$"
        local cursor_at_end = col_cursor + 1 >= col_end

        vim.fn["wiki#link#add"](path, { transform_relative = true })

        if insert_mode then
          if cursor_at_end then
            vim.cmd "startinsert!"
          else
            vim.cmd "startinsert"
          end
        end
      end)
      return true
    end,
  }, opts or {}))
end

return M
