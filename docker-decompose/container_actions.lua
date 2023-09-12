local Terminal = require("toggleterm.terminal").Terminal

local M = {}

-- Can be extended to be toggle-able between all buffers open for ssh-ing into containers
function M.run_command_in_container(container, cmd)
    local terminal = Terminal:new({cmd = string.format("docker exec -it %s %s", container, cmd), hidden = true})
    terminal:toggle()
end

function M.get_docker_container_logs(container)
    local terminal = Terminal:new({cmd = string.format("docker logs --timestamps -f %s", container), hidden = true})
    terminal:toggle()
end

function M.start_docker_compose_container(bufnr, container)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local cmd = "docker"
    local arguments = {"compose", "-f", filename, "up", container}
    vim.loop.spawn(cmd, {args = arguments, stdio = {nil, nil, nil}}, function() end)
end

function M.stop_docker_compose_container(bufnr, container)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local cmd = "docker"
    local arguments = {"compose", "-f", filename, "stop", container}
    vim.loop.spawn(cmd, {args = arguments, stdio = {nil, nil, nil}}, function() end)
end

function M.get_docker_container_status(container)
    local terminal = Terminal:new({cmd = string.format("docker compose ps %s", container), hidden = true})
    terminal:toggle()
end

return M
