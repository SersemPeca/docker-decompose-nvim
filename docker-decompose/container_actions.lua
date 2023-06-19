local Terminal = require("toggleterm.terminal").Terminal

-- Can be extended to be toggle-able between all buffers open for ssh-ing into containers
local function run_command_in_container(container, cmd)
   local terminal =  Terminal:new({cmd = string.format("docker exec -it %s %s", container, cmd), hidden = true})
   terminal:toggle()
end

local function get_docker_container_logs(container)
    local terminal = Terminal:new({cmd = string.format("docker logs --timestamps %s", container), hidden = true})
    terminal:toggle()
end

local function stop_docker_container(bufnr, container, on_exit)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local cmd = "docker"
    local arguments = {"compose", "-f",filename,"stop", container}
    vim.loop.spawn(cmd, {args = arguments, stdio = {nil, nil, nil}}, on_exit)
end

local function start_docker_container(bufnr, container, on_exit)
    local filename = vim.api.nvim_buf_get_name(bufnr)
    local cmd = "docker"
    local arguments = {"compose","-f", filename, "up", container}
    vim.loop.spawn(cmd, {args = arguments, stdio = {nil, nil, nil}}, on_exit)
end

local function get_docker_container_status(container)
    local terminal = Terminal:new({cmd = string.format("docker compose ps %s", container), hidden = true})
    terminal:toggle()
end

return {
    run_command_in_container = run_command_in_container,
    get_docker_container_logs = get_docker_container_logs,
    get_docker_container_status = get_docker_container_status,
    stop_docker_container = stop_docker_container,
    start_docker_container = start_docker_container,
}
