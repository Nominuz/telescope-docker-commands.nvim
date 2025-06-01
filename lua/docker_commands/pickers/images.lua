local log = require("plenary.log").new {
  plugin = "docker_commands.images",
  level = "info",
}

local td_utils = require "docker_commands.utils"

local M = {}

M.docker_images = function(opts)
  local entry_maker_fn = function(entry)
    local image = vim.json.decode(entry)
    log.debug("Images entry_maker_fn received entry:", entry)
    if image then
      local display_text = image.Repository or image.ID or "Unknown Image"
      if display_text == "<none>" then
        display_text = image.ID or "Unknown Image" -- Use ID if Repository is <none>
      end
      local ordinal_text =
        string.lower(display_text .. " " .. (image.Tag or "") .. " " .. (image.ID or ""))

      return {
        value = image,
        display = display_text,
        ordinal = ordinal_text,
      }
    end
    log.warn("Images entry maker returned nil for entry:", entry)
    return nil -- Explicitly return nil if decoding fails
  end

  local define_preview_fn = function(self, entry)
    local formatted = {
      "# " .. entry.display,
      "",
      "**Repository**: " .. entry.value.Repository,
      "**ID**: " .. entry.value.ID,
      "**Tag**: " .. entry.value.Tag,
      "**Containers**: " .. entry.value.Containers,
      "**Size**: " .. entry.value.Size,
    }
    vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, formatted)
  end

  -- Use the helper from td_utils
  return td_utils
    .create_dynamic_docker_picker(

      require("docker_commands").config, -- Access the main config
      "images",
      { "images" },
      entry_maker_fn,
      "Image Details",
      define_preview_fn,
      opts
    )
    :find()
end

return M
