local M = {}

function M.get_pages()
    local res = {}
    local pages = vim.fn["wiki#page#get_all"]()
    for _, p in pairs(pages) do
        table.insert(res, p[1])
    end
    vim.ui.select(res,
        { prompt = "WikiPages> " },
        function(f)
            vim.cmd("edit " .. f)
        end)
end

function M.get_tags()
    local res = {}
    local tags = vim.fn["wiki#tags#get_all"]()
    for key, val in pairs(tags) do
        for _, file in pairs(val) do
            local str = string.format("%s: %s:%s", key, file[1], file[2])
            table.insert(res, str)
        end
    end
    vim.ui.select(res,
        { prompt = "WikiTags> " },
        function(t)
            t = vim.split(t, ':')[2]
            vim.cmd("edit " .. t)
        end)
    return res
end

function M.toc()
    local res = {}
    local toc = vim.fn["wiki#toc#gather_entries"]()
    for _, hd in pairs(toc) do
        local indent = vim.fn["repeat"]('.', hd.level - 1)
        local line = hd.lnum .. ': ' .. indent .. hd.header
        table.insert(res, line)
    end
    vim.ui.select(res,
        { prompt = "WikiToc> ", },
        function(t)
            t = vim.split(t, ':')[1]
            vim.cmd("execute " .. t)
        end)
end

return M
