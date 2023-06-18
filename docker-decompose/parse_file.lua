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
     for pattern, match, metadata in query:iter_matches(root, bufnr, 0, -1) do
         for id, node in pairs(match) do
            local name = query.captures[id]
            if (name == "service") then
                vim.print(string.format("Captured %s with value %s", name, vim.treesitter.get_node_text(node, bufnr)))
            end
         end
     end
 end

 return init
