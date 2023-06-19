
local is_docker_container_running = function(container)
    local container_status = vim.fn.system(string.format("docker container inspect -f '{{.State.Status}}' %s", container), nil)
    container_status = container_status:gsub("[\n\r]", "")
    return container_status == "running"
end

return is_docker_container_running
