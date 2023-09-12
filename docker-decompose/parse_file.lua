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
local utils = require("docker-decompose.utils")

local function init()
    local bufnr = vim.api.nvim_get_current_buf()

    if (vim.bo[bufnr].filetype ~= "yaml") then
        vim.notify("This plugin is only meant to be used for yaml files")
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
                       key: (_) @service))))
       (#lua-match? @_key "services"))
    ]]

    local parser = vim.treesitter.get_parser(bufnr, "yaml", nil)

    local root = parser:parse()[1]:root()

    local query = vim.treesitter.query.parse("yaml" , query_string)

    -- Clear old (if any) contaniers for this bufnr
    if cache[bufnr] then
        local ns = vim.api.nvim_create_namespace("docker-decompose")
        vim.api.nvim_buf_clear_namespace(bufnr, ns, 0, -1)
    end
    cache[bufnr] = {}

    -- Fill the cache for this bufnr
    for _pattern, match, _metadata in query:iter_matches(root, bufnr, 0, -1) do
        for id, node in pairs(match) do
            local name = query.captures[id]
            if (name == "service") then
                cache[bufnr][vim.treesitter.get_node_text(node, bufnr, nil)] = {
                    node = node,
                }
            end
        end
    end

    utils.populate_container_status(bufnr)

    utils.start_listening_for_events(bufnr)
end

return init
