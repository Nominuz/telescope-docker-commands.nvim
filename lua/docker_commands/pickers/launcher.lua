local td_utils = require "docker_commands.utils"
local action_state = require "telescope.actions.state"
local actions = require "telescope.actions"

-- Define available Docker functionalities and their corresponding actions
local options = {
  -- Add 'type' field to map to the keys in M.config.actions for previewing
  {
    name = "Containers",
    type = "containers",
    action = function() require("docker_commands").docker_containers() end,
  },
  {
    name = "Images",
    type = "images",
    action = function() require("docker_commands").docker_images() end,
  },
  {
    name = "Volumes",
    type = "volumes",
    action = function() require("docker_commands").docker_volumes() end,
  },
  {
    name = "Networks",
    type = "networks",
    action = function() require("docker_commands").docker_networks() end,
  },
  {
    name = "System",
    type = "system",
    action = function() require("docker_commands").docker_system() end,
  },
}

local system_picker = require "docker_commands.pickers.system" -- Require system picker to access entries

local M = {}

M.docker_launcher = function(opts)
  local picker = td_utils.pickers.new(opts, {
    prompt_title = "Docker Actions Launcher",
    finder = td_utils.finders.new_table {
      results = options,
      entry_maker = function(entry)
        return {
          -- Store both type and action function in value for preview and execution
          value = { type = entry.type, action = entry.action },
          display = entry.name, -- Display the name
          ordinal = entry.name, -- Use name for sorting/filtering
        }
      end,
    },
    sorter = td_utils.conf.generic_sorter(opts),
    -- Add a previewer to show available actions for the selected picker type
    previewer = td_utils.previewers.new_buffer_previewer {
      title = "Available Actions",
      define_preview = function(self, entry)
        local picker_type = entry.value.type -- Get the picker type from the entry value
        local docker_commands_module = require("docker_commands") -- Get the module to check config

        local lines = {}
        table.insert(lines, "# Actions for " .. entry.display)
        table.insert(lines, "")

        if picker_type == "system" then
          -- For the system picker, list the available system commands from the config
          table.insert(lines, "Available System Commands:")
          table.insert(lines, "")
          local system_commands_config = docker_commands_module.config.actions.system or {}
          -- Iterate over the values of the system_commands map
          for _, system_entry in pairs(system_commands_config) do
          -- Ensure the entry has the necessary fields before displaying
          -- Check for command_args and display
          if system_entry and system_entry.command_args and system_entry.display then
            local command_str = "docker " .. vim.fn.join(system_entry.command_args, " ") -- Use command_args
            local confirmation_note = system_entry.needs_confirmation and " (requires confirmation)" or ""
            table.insert(
              lines,
              string.format(
                "- **%s**: `%s`%s",
                system_entry.display,
                command_str,
                confirmation_note
              )
            )
          end
        end
          -- For other picker types, list the configured actions if config is available
          local actions_config = docker_commands_module.config.actions[picker_type]

          if actions_config then
            local cr_action_data = nil
            local cr_action_name = nil

            -- Find the action mapped to <CR> first
            for action_name, action_data in pairs(actions_config) do
              if type(action_data) == "table" and action_data.key == "<CR>" then
                cr_action_data = action_data
                cr_action_name = action_name
                break -- Found the <CR> action, exit loop
              end
            end

            -- Add the <CR> action first if found
            if cr_action_data then
              local key_display = cr_action_data.key or "No keybinding"
              local desc_display = cr_action_data.desc or "No description"
              table.insert(
                lines,
                string.format("- **%s**: `%s` (%s)", cr_action_name, key_display, desc_display)
              )
            end

            -- Add all other actions
            for action_name, action_data in pairs(actions_config) do
              -- Ensure action_data is a valid table and not the <CR> action we already added
              if type(action_data) == "table" and action_data.key ~= "<CR>" then
                local key_display = action_data.key or "No keybinding"
                local desc_display = action_data.desc or "No description"
                table.insert(
                  lines,
                  string.format("- **%s**: `%s` (%s)", action_name, key_display, desc_display)
                )
              end
            end
          else
            table.insert(lines, "No specific actions defined for this picker type.")
          end
        else
          -- Handle the case where config or actions are nil
          table.insert(lines, "Plugin configuration not loaded.")
          table.insert(lines, "Please ensure require('docker_commands').setup({}) has been called in your Neovim config.")
        end

        -- Clear existing lines and set the new formatted lines in the preview buffer
        vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        -- Use markdown highlighter for better readability
        td_utils.utils.highlighter(self.state.bufnr, "markdown")
      end,
    },
    attach_mappings = function(prompt_bufnr)
      -- Map <CR> to execute the selected action
      actions.select_default:replace(function()
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)
        -- Execute the stored action function (now accessed via selection.value.action)
        if type(selection.value.action) == "function" then selection.value.action() end
      end)
      return true
    end,
  })

  -- Return the picker instance and find it
  return picker:find()
end

return M
