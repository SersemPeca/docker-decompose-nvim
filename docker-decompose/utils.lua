local cache = require("docker-decompose.cache")

local M = {}

function M.mysplit (inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end

function M.is_docker_container_running(container)
    local container_status = vim.fn.system(string.format("docker container inspect -f '{{.State.Status}}' %s", container))
    container_status = container_status:gsub("[\n\r]", "")
    return container_status == "running"
end

function M.get_docker_container_ports(container)
    return vim.fn.system(string.format("docker port %s", container))
end

function M.get_running_docker_containers()
    local containers = vim.fn.system("docker ps --format '{{.Names}}'", nil)
    containers = M.mysplit(containers, "\n")
    return containers
end

function M.populate_container_status(bufnr)
    for container, data in pairs(cache[bufnr]) do
        -- utils.is_docker_container_running(name)
        local status = M.is_docker_container_running(M.get_container_name(bufnr, container)) and "RUNNING" or "STOPPED"
        local ports = status == "RUNNING" and M.get_docker_container_ports(M.get_container_name(bufnr, container)) or ""
        M.set_extmark(bufnr, container, {
            status = status,
            ports = ports,
        })
    end
end

function M.start_listening_for_events(bufnr)
    local events_stdout = vim.loop.new_pipe()
    local cmd = "docker"
    local args = { "events" }
    for name, _ in pairs(cache[bufnr]) do
        table.insert(args, "--filter")
        table.insert(args, string.format("container=%s", name))
        table.insert(args, "--format")
        table.insert(args, string.format("{{json .}}"))
    end
    local handle = nil

    local on_exit = function(code, status)
        vim.loop.read_stop(events_stdout)
        vim.loop.close(events_stdout)
        vim.loop.close(handle)
        vim.notify("Events commands stopped")
    end
    local on_event = function(_status, data)
        if data then
            local info = vim.json.decode(data)

            if vim.tbl_contains({"start", "stop"}, info.status) then
               vim.schedule(function()
                    local container_name = info["Actor"]["Attributes"]["com.docker.compose.service"]
                    local status = info.status == "start" and "RUNNING" or "STOPPED"

                    local ports = status == "RUNNING" and M.get_docker_container_ports(M.get_container_name(bufnr, container_name)) or ""

                    M.set_extmark(bufnr, container_name, {
                        -- TODO: better naming
                        status = info.status == "start" and "RUNNING" or "STOPPED",
                        ports = ports,
                    })
               end)
           end
        end
    end
    handle = vim.loop.spawn(cmd, {args = args, stdio = {nil, events_stdout, nil}}, on_exit)
    vim.loop.read_start(events_stdout, on_event)
end

function M.set_extmark(bufnr, container, info)
    local ns = vim.api.nvim_create_namespace("docker-decompose")
    local hl_group = "CurSearch"

    local data = cache[bufnr][container]

    local start_row, start_col, _, _
        = vim.treesitter.get_node_range(data.node)

    local virt_lines = {
        {{string.rep(' ', start_col) .. "Status: ", hl_group}, {info.status, hl_group}},
    }

    local first = true
    for _, port in ipairs(vim.split(info.ports, "\n")) do
        if port ~= "" then
            if first then
                table.insert(virt_lines, {{string.rep(' ', start_col) .. "Ports: ", hl_group}, {port, hl_group}})
                first = false
            else
                table.insert(virt_lines, {{string.rep(' ', start_col + 7), hl_group}, {port, hl_group}})
            end
        end
    end

    data.extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns, start_row, start_col, {
        id = data.extmark_id, -- TODO: why not work men
        hl_group = "DiagnosticInfo",
        virt_lines = virt_lines,
    })
end

function M.get_container_name(bufnr, image)

    local compose_path = vim.api.nvim_buf_get_name(bufnr)

    local container_id = vim.fn.system(
        string.format(
            [[docker compose -f "%s" ps -q "%s"]],
            compose_path,
            image
        )
    )
    container_id = string.gsub(container_id, "\n", "")

    local container_name = vim.fn.system(
        string.format(
            [[docker inspect -f "{{.Name}}" "%s"]],
            container_id
        )
    )
    container_name = string.gsub(container_name, "\n", "")
    container_name = string.sub(container_name, 2)

    return container_name
end

return M
