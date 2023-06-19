-- :h vim.treesitter.get_parser
-- :h vim.treesitter.query.parse
-- :h vim.api.nvim_get_current_buf
-- :h vim.notify
-- :h vim.print
-- :h Query:iter_matches()
-- :h TSNode
-- :h TSNode:iter_children()
-- :h vim.api.nvim_create_autocmd
-- :h vim.api.nvim_create_user_command

-- Is cached in package-loaded table under key "docker-compose.cache"
local cache = require("docker-decompose.cache")

local function init()
    local bufnr = vim.api.nvim_get_current_buf()

    if (vim.bo[bufnr].filetype ~= "yaml") then
        vim.notify("Mn si prost")
        return
    end

    local query_string = [[

    ((block_mapping_pair
    key: (flow_node 
    (plain_scalar 
    (string_scalar))) @_key
    value: (block_node
    (block_mapping
    (block_mapping_pair
    key: (_) @service
    )))

    )
    (#lua-match? @_key "services"))
    ]]

    local parser = vim.treesitter.get_parser(bufnr, "yaml", nil)

    local root = parser:parse()[1]:root()

    local query = vim.treesitter.query.parse("yaml" , query_string)
    local ns = vim.api.nvim_create_namespace("docker-decompose")
    local hl_group = "CurSearch"

    for _pattern, match, _metadata in query:iter_matches(root, bufnr, 0, -1) do
        for id, node in pairs(match) do
            local name = query.captures[id]
            if (name == "service") then
                cache[vim.treesitter.get_node_text(node, bufnr, nil)] = {bufnr = bufnr, node = node}
            end
        end
    end

    for _name, pair in pairs(cache) do
        local start_row, start_col, end_row, end_col
            = vim.treesitter.get_node_range(pair.node)
        vim.api.nvim_buf_set_extmark(pair.bufnr, ns, start_row, start_col, {
            end_row = end_row,
            end_col = end_col,
            hl_group = "DiagnosticInfo",
            virt_lines = {
                {{string.rep(' ', start_col).."Status: ", hl_group}, {"ALIVE", hl_group}},
                {{string.rep(' ', start_col).."Port: 8080", hl_group}},
            },
        })
    end
end

return init
