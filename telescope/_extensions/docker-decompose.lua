return require("telescope").register_extension {
    exports = {
      docker_decompose = require("docker-decompose.picker"),
    }
}
