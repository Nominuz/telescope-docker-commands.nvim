local log = require("plenary.log").new {
  plugin = "docker_commands.volumes",
  level = "info",
}

local td_utils = require "docker_commands.utils"

local M = {}

M.docker_volumes = function(opts)
  local entry_maker_fn = function(entry)
    local volume = vim.json.decode(entry)
    if volume then
      return {
        value = volume,
        display = volume.Name,
        ordinal = volume.Name,
      }
    end
    log.warn("Entry maker returned nil for entry:", entry)
    return nil -- Explicitly return nil if decoding fails
  end

  local define_preview_fn = function(self, entry)
    local formatted = {
      "# " .. entry.display,
      "",
      "**Driver**: " .. entry.value.Driver,
      "**Labels**: " .. entry.value.Labels,
      "**Availability**: " .. entry.value.Availability,
      "**Group**: " .. entry.value.Group,
      "**Links**: " .. entry.value.Links,
      "**Scope**: " .. entry.value.Scope,
      "**Size**: " .. entry.value.Size,
      "**Status**: " .. entry.value.Status,
      "**Mountpoint**: " .. entry.value.Mountpoint,
    }
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, formatted)
  end

  -- Use the helper from td_utils
  return td_utils
    .create_dynamic_docker_picker(

      require("docker_commands").config, -- Access the main config
      "volumes",
      { "volume", "ls" },
      entry_maker_fn,
      "Volume Details",
      define_preview_fn,
      opts
    )
    :find()
end

return M
