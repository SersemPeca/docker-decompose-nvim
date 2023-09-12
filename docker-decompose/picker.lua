local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local sorters = require("telescope.sorters")
local previewers = require("telescope.previewers")
local action_state = require("telescope.actions.state")
local conf = require("telescope.config").values

local cache = require("docker-decompose.cache")
local utils = require("docker-decompose.utils")
local container_actions = require("docker-decompose.container_actions")


local container_picker = function(opts)
    opts = opts or {}

    local picker_results = {}

    if opts.bufnr and cache[opts.bufnr] then
        -- User-chosen docker-compose buffer
        for name, data in pairs(cache[opts.bufnr]) do
            table.insert(picker_results, {name, opts.bufnr, data.node})
        end
    else
        -- All docker-compose buffers
        for bufnr, containers in pairs(cache) do
            for name, data in pairs(containers) do
                table.insert(picker_results, {name = name, bufnr = bufnr, node = data.node})
            end
        end
    end

    return pickers.new(opts, {
        prompt_title = "Select container",
        finder = finders.new_table({
            results = picker_results,
            selection = action_state.get_selected_entry(),
            entry_maker = function(entry)
                local display = string.format(
                    "%s: %s",
                    vim.api.nvim_buf_get_name(entry.bufnr),
                    entry.name
                )
                return {
                    value = entry,
                    display = display,
                    ordinal = display, -- tostring(entry.bufnr),
                }
            end
        }),
        sorter = sorters.get_generic_fuzzy_sorter(),
        previewer = previewers.new_buffer_previewer({
            define_preview = function(self, entry, _status)
                require("telescope.previewers.utils").job_maker(
                    {
                        "docker",
                        "ps",
                        "--filter",
                        string.format(
                            "name=%s",
                            utils.get_container_name(entry.value.bufnr, entry.value.name)
                        ),
                    },
                    self.state.bufnr,
                    {}
                )
            end,
        }),
        attach_mappings = function(prompt_bufnr, _map)
            actions.select_default:replace(function()
                local selected_container = action_state.get_selected_entry()

                local started_results = {
                    "stop_container",
                    "exec_into_container",
                    "open_container_logs",
                }

                local stopped_results = {
                    "start_container",
                }

                actions.close(prompt_bufnr)

                pickers:new{
                    prompt_title = "Select option",
                    finder = finders.new_table({
                        results = utils.is_docker_container_running(
                            utils.get_container_name(
                                selected_container.value.bufnr,
                                selected_container.value.name
                            )
                        ) and started_results or stopped_results,
                    }),
                    sorter = sorters.get_generic_fuzzy_sorter(),
                    attach_mappings = function(prompt_bufnr1)
                        actions.select_default:replace(
                        function ()
                            local selection = action_state.get_selected_entry()
                            actions.close(prompt_bufnr1)
                            local get_real_container_name = function()
                                return utils.get_container_name(selected_container.value.bufnr, selected_container.value.name)
                            end
                            local operations = {
                                exec_into_container = function()
                                    container_actions.run_command_in_container(
                                        get_real_container_name(),
                                        "/bin/bash"
                                    )
                                end,
                                open_container_logs = function()
                                    container_actions.get_docker_container_logs(
                                        get_real_container_name()
                                    )
                                end,
                                start_container = function()
                                    container_actions.start_docker_compose_container(
                                        selected_container.value.bufnr,
                                        selected_container.value.name
                                    )
                                end,
                                stop_container = function()
                                    container_actions.stop_docker_compose_container(
                                        selected_container.value.bufnr,
                                        selected_container.value.name
                                    )
                                end,
                            }
                            operations[selection.value]()
                        end
                        )
                        return true
                    end
                }:find()
            end)
            return true
        end,
    }):find()
end

return container_picker
