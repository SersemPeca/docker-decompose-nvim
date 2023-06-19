local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local cache = require("docker-decompose.cache")
local containers = {}

for k, v in pairs(cache) do
    table.insert(containers, {k, v["bufnr"], v["node"]})
end

local operations_picker = function(opts, selected_container)
    pickers.new(opts, {
        prompt_title = "Select operation",
        finder = finders.new_table({
            results = {
                "Sneed",
                "Option 2",
                "Option 3",
            },

        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local operations = {
                    green = function(col) print(col) end,
                    red = function(col) print(col) end,
                    blue = function(col) print(col) end,
                }
                print(vim.inspect(cache))
            end)
            return true
        end,
    }):find()
end

local container_picker = function(opts)
    opts = opts or {}
    return pickers.new(opts, {
        prompt_title = "",
        finder = finders.new_table({
            results = containers,
            entry_maker = function(entry)
                return {
                    value = entry,
                    display = entry[1],
                    ordinal = entry[1],
                }
            end

        }),
        sorter = conf.generic_sorter(opts),
        attach_mappings = function(prompt_bufnr, _map)
            actions.select_default:replace(function()
                actions.close(prompt_bufnr)
                local selection = action_state.get_selected_entry()
                operations_picker(opts, selection)
            end)
            return true
        end,
    }):find()
end

return container_picker
