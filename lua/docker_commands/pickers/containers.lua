local log = require("plenary.log").new {
  plugin = "docker_commands.containers",
  level = "info",
}

local td_utils = require "docker_commands.utils"

local M = {}

M.docker_containers = function(opts)
  local entry_maker_fn = function(entry)
    local process = vim.json.decode(entry)
    if process then
      return {
        value = process,
        display = process.State .. " " .. process.Names .. " " .. process.Image,
        -- Include State, Names, Image, and ID in the ordinal for filtering
        ordinal = string.lower(
          process.State .. " " .. process.Names .. " " .. process.Image .. " " .. process.ID
        ),
      }
    end
    log.warn("Entry maker returned nil for entry:", entry)
    return nil -- Explicitly return nil if decoding fails
  end

  local define_preview_fn = function(self, entry)
    local formatted = {
      "# ID: " .. entry.value.ID,
      "",
      "**Names**: " .. entry.value.Names,
      "**Labels**: " .. entry.value.Labels,
      "",
      "**Image**: " .. entry.value.Image,
      "**LocalVolumes**: " .. entry.value.LocalVolumes,
      "**Mounts**: " .. entry.value.Mounts,
      "**Networks**: " .. entry.value.Networks,
      "**Ports**: " .. entry.value.Ports,
      "",
      "**Size**: " .. entry.value.Size,
      "",
      "**State**: " .. entry.value.State,
      "**RunningFor**: " .. entry.value.RunningFor,
    }
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, formatted)
  end

  -- Use the helper from td_utils
  return td_utils
    .create_dynamic_docker_picker(

      require("docker_commands").config, -- Access the main config
      "containers",
      { "ps", "-a" },
      entry_maker_fn,
      "Process Details",
      define_preview_fn,
      opts
    )
    :find()
end

return M
