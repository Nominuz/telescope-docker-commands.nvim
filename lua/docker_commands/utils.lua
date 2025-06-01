local plenary = require "plenary"
local log = require("plenary.log").new {
  plugin = "docker_commands",
  level = "info",
}

local M = {} -- Define M before using it

-- Require common Telescope modules here
M.conf = require("telescope.config").values
M.pickers = require "telescope.pickers"
M.finders = require "telescope.finders"
M.previewers = require "telescope.previewers"
M.utils = require "telescope.previewers.utils"

---Ask for user confirmation with a yes/no prompt
---@param message string The confirmation message to show
---@return boolean true if user confirmed, false otherwise
M.confirm_action = function(message)
  local choice = vim.fn.confirm(message, "&Yes\n&No", 2) -- 2 is the default choice (No)
  return choice == 1
end

--- Executes a docker command in a terminal buffer after optional confirmation.
--- This is an internal helper function.
---@param full_command_args string[] The complete list of arguments for the docker command.
---@param needs_confirmation boolean Whether to ask for confirmation using the Lua prompt before executing.
---@param confirmation_target_display string The string to display in the confirmation message (e.g., container ID, command name).
M.execute_docker_command = function(
  full_command_args,
  needs_confirmation,
  confirmation_target_display
)
  local command_to_execute = vim.deepcopy(full_command_args) -- Create a copy to potentially modify

  -- Handle confirmation message
  if needs_confirmation then
    -- Use the original command args for the confirmation message display
    local msg = string.format(
      "Are you sure you want to run 'docker %s' on %s?",
      vim.fn.join(full_command_args, " "),
      confirmation_target_display
    )
    if not M.confirm_action(msg) then
      vim.notify("Operation cancelled.", vim.log.levels.INFO)
      log.info "Operation cancelled by user."
      return
    end
  end

  -- If confirmed (or if no confirmation was needed) and it's a prune command, add the -f flag
  -- Check the original command_args for 'prune' before adding -f
  -- This ensures Docker's terminal confirmation is bypassed since we already confirmed.
  if vim.tbl_contains(full_command_args, "prune") then table.insert(command_to_execute, "-f") end

  local full_command = M.flatten_table {
    "vnew",
    "term://docker",
    command_to_execute, -- Use the potentially modified command_to_execute
  }

  log.info("Executing docker command:", vim.fn.join(full_command, " "))
  vim.cmd(vim.fn.join(full_command, " "))
end

--- Executes a docker command that operates on a specific object (container, image, volume, network).
---@param command_args string[] Arguments for the command before the object identifier (e.g., {"exec", "-it"} or {"rm"}).
---@param entry_value table The full selected entry value (the decoded JSON object).
---@param identifier string The specific identifier (ID or Name) to use for the command.
---@param needs_confirmation boolean Whether to ask for confirmation before executing the command.
M.run_object_command = function(command_args, entry_value, identifier, needs_confirmation)
  local full_command_args = M.flatten_table {
    command_args,
    identifier,
  }
  local confirmation_target_display = identifier

  -- Add shell at the end for 'exec -it' commands
  -- We need the full entry_value to get the Image name
  if vim.tbl_contains(command_args, "exec") and vim.tbl_contains(command_args, "-it") then
    -- Ensure entry_value and entry_value.Image exist before calling get_shell
    if entry_value and entry_value.Image then
      table.insert(full_command_args, M.get_shell(entry_value.Image))
    else
      log.warn("Could not get image name for exec command.")
      -- Fallback to a default shell if image name is not available
      table.insert(full_command_args, "sh")
    end
  end

  M.execute_docker_command(full_command_args, needs_confirmation, confirmation_target_display)
end

--- Executes a docker command that does not operate on a specific object (e.g., system commands).
--- For commands requiring confirmation (like prune), this function passes the confirmation flag
--- to execute_docker_command, which handles the Lua confirmation and adds the -f flag if needed.
---@param command_args string[] The complete list of arguments for the docker command (e.g., {"system", "df"}).
---@param needs_confirmation boolean Whether to perform a Lua confirmation before executing.
M.run_system_command = function(command_args, needs_confirmation)
  local confirmation_target_display = vim.fn.join(command_args, " ")

  -- Pass the confirmation flag directly to execute_docker_command
  M.execute_docker_command(command_args, needs_confirmation, confirmation_target_display)
end

-- List of shells to try, in order of preference
local SUPPORTED_SHELLS = {
  { name = "sh", path = "/bin/sh" },
  { name = "bash", path = "/bin/bash" },
  { name = "zsh", path = "/bin/zsh" },
}

-- Some containers may not have a default interactive shell.
-- This function attempts to find the best available shell for interactive sessions.
---@param container string Docker container name
---@return string|nil shell_name Name of the shell found or nil if none available
M.get_shell = function(container)
  -- Use a single docker run to check all shells at once
  local cmd = table.concat({
    "docker",
    "run",
    "--rm",
    container,
    -- Use find to check multiple paths at once, more efficient than multiple which commands
    "find",
    "/bin/sh",
    "/bin/bash",
    "/bin/zsh",
    "-maxdepth",
    "0",
    "-type",
    "f",
    "-executable",
    "2>/dev/null",
  }, " ")

  local job = plenary.job:new {
    command = "sh",
    args = { "-c", cmd },
    on_stderr = function(_, data)
      if data then log.warn("Error checking shells:", data) end
    end,
  }

  local output = job:sync()

  -- Check available shells in order of preference
  for _, shell in ipairs(SUPPORTED_SHELLS) do
    for _, line in ipairs(output) do
      if line == shell.path then return shell.name end
    end
  end

  log.warn("No supported shell found in container:", container)
  return "sh" -- Fallback to sh as last resort
end

--- Helper function to flatten a table (shallow flatten)
--- This replaces the deprecated vim.tbl_flatten
---@param tbl table The table to flatten
---@return table The flattened table
M.flatten_table = function(tbl)
  local result = {}
  for _, v in ipairs(tbl) do
    if type(v) == "table" then
      for _, inner_v in ipairs(v) do
        table.insert(result, inner_v)
      end
    else
      table.insert(result, v)
    end
  end
  return result
end

---@param args string[]
---@return string[]
M._make_docker_command = function(args)
  local job_opts = {
    command = "docker",
    args = M.flatten_table { args, "--format", "json" },
  }
  local job = plenary.job:new(job_opts):sync()
  return job
end

-- Helper function to handle mappings consistently across all pickers
-- This makes it very easy to overwrite mappings in setup
---@param prompt_bufnr number
---@param map fun(modes: string|string[], key: string, action: fun(prompt_bufnr: number, ...), opts?: table)
---@param picker_mappings_config table<string, {action: fun(prompt_bufnr: number, ...), desc: string}>|nil
---@return boolean
M.handle_mappings = function(prompt_bufnr, map, picker_mappings_config)
  local actions = require "telescope.actions"
  local action_state = require "telescope.actions.state"

  -- Handle <CR> separately using select_default
  -- Check if a mapping for <CR> exists in the generated mappings
  if picker_mappings_config and picker_mappings_config["<CR>"] then
    actions.select_default:replace(picker_mappings_config["<CR>"].action)
  else
    -- Fallback to default Telescope select action if <CR> is not mapped
    actions.select_default:replace(function() actions.close(prompt_bufnr) end)
  end

  -- Apply all other mappings from the generated config
  if picker_mappings_config then
    for key, mapping_data in pairs(picker_mappings_config) do
      if key ~= "<CR>" then -- Skip the default select action, already handled above
        -- mapping_data should always be a table with action/desc at this point
        -- because nil/empty key actions were filtered in setup
        if type(mapping_data) == "table" and mapping_data.action then
          map({ "i", "n" }, key, mapping_data.action, { desc = mapping_data.desc or "" })
        end
      end
    end
  end

  return true
end

--- Helper function to create a dynamic Docker picker

---@param config table The current plugin configuration (M.config)
---@param picker_type string The type of picker (e.g., "containers", "volumes")
---@param command_args table Arguments for td_utils._make_docker_command
---@param entry_maker_fn fun(entry: string): table The function to create picker entries
---@param preview_title string The title for the preview buffer
---@param define_preview_fn fun(self: table, entry: table) The function to define preview buffer content
---@param opts table Options passed to pickers.new
M.create_dynamic_docker_picker = function(
  config,
  picker_type,
  command_args,
  entry_maker_fn,
  preview_title,
  define_preview_fn,
  opts
)
  return M.pickers.new(opts, {
    finder = M.finders.new_dynamic {
      fn = function() return M._make_docker_command(command_args) end,
      entry_maker = entry_maker_fn,
    },
    sorter = M.conf.generic_sorter(opts),
    previewer = M.previewers.new_buffer_previewer {
      title = preview_title,
      define_preview = function(self, entry)
        define_preview_fn(self, entry) -- Call the provided define_preview function
        M.utils.highlighter(self.state.bufnr, "markdown") -- Common highlighter
      end,
    },
    attach_mappings = function(prompt_bufnr, map)
      -- Use the mappings for the specific picker type
      return M.handle_mappings(prompt_bufnr, map, config.mappings[picker_type])
    end,
  })
end

return M
