local log = require("plenary.log").new {
  plugin = "docker_commands.networks",
  level = "info",
}

local td_utils = require "docker_commands.utils"

local M = {}

M.docker_networks = function(opts)
  local entry_maker_fn = function(entry)
    local network = vim.json.decode(entry)
    if network then
      return {
        value = network,
        display = network.Name,
        ordinal = network.Name .. " " .. network.ID .. " " .. network.Driver,
      }
    end
    log.warn("Entry maker returned nil for entry:", entry)
    return nil -- Explicitly return nil if decoding fails
  end

  local define_preview_fn = function(self, entry)
    local formatted = {
      "# " .. entry.display,
      "",
      "**ID**: " .. entry.value.ID,
      "**Name**: " .. entry.value.Name,
      "**Driver**: " .. entry.value.Driver,
      "**Scope**: " .. entry.value.Scope,
    }
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, formatted)
  end

  -- Use the helper from td_utils
  return td_utils
    .create_dynamic_docker_picker(

      require("docker_commands").config, -- Access the main config
      "networks",
      { "network", "ls" },
      entry_maker_fn,
      "Network Details",
      define_preview_fn,
      opts
    )
    :find()
end

return M
