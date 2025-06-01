return require("telescope").register_extension {
  exports = {
    -- Make docker_launcher the default action when calling :Telescope docker_commands
    docker_commands = require("docker_commands").docker_launcher,
    docker_launcher = require("docker_commands").docker_launcher,
    docker_images = require("docker_commands").docker_images,
    docker_containers = require("docker_commands").docker_containers,
    docker_volumes = require("docker_commands").docker_volumes,
    docker_system = require("docker_commands").docker_system,
    docker_networks = require("docker_commands").docker_networks,
  },
}
