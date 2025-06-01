local td_utils = require "docker_commands.utils"
local log = require("plenary.log").new { plugin = "docker_commands.system" } -- Ensure log is available

local M = {}


M.docker_system = function(opts)
  -- Get system commands from the main configuration (expected to be a map)
  local system_commands_config = require("docker_commands").config.actions.system or {}

  -- Convert the map of system commands into a list of values for the finder
  local system_commands_list = {}
  for _, command_data in pairs(system_commands_config) do
    -- Ensure the entry has the necessary fields before adding to the list
    -- Check for command_args and display
    if command_data and command_data.command_args and command_data.display then
      table.insert(system_commands_list, command_data)
    else
      -- Log a warning if a system command entry is misconfigured in the config
      require("plenary.log").new { plugin = "docker_commands.system" }
        .warn("Misconfigured system command entry in config:", vim.inspect(command_data))
    end
  end

  -- Sort the list based on the 'order' field
  table.sort(system_commands_list, function(a, b)
    -- Default order to a high number if not specified, so entries without order go to the end
    local order_a = a.order or math.huge
    local order_b = b.order or math.huge
    return order_a < order_b
  end)


  td_utils.pickers
    .new(opts, {
      prompt_title = "Docker System Commands",
      finder = td_utils.finders.new_table {
        results = system_commands_list, -- Use the sorted list of configured system commands
        entry_maker = function(entry)
          -- 'entry' here is the command_data table from the sorted list
          -- We already filtered for necessary fields when creating the list,
          -- but a final check here is harmless.
          if entry and entry.command_args and entry.display then
            return {
              value = {
                command_args = entry.command_args, -- Use command_args here
                needs_confirmation = entry.needs_confirmation or false, -- Default to false
              },
              display = entry.display,
              ordinal = entry.display, -- Use display for Telescope's sorting/filtering
            }
          end
          -- This case should ideally not happen if list creation filtered correctly
          require("plenary.log").new { plugin = "docker_commands.system" }
            .warn("Entry maker received misconfigured entry after list creation:", vim.inspect(entry))
          return nil -- Skip misconfigured entries
        end,
      },
      -- The generic_sorter will sort by ordinal when the user types,
      -- but the initial display order comes from the 'results' list order.
      sorter = td_utils.conf.generic_sorter(opts),
      attach_mappings = function(prompt_bufnr, map)
        -- The <CR> action for the system picker is now generated in init.lua's setup
        -- and added to M.config.mappings.system["<CR>"].
        -- td_utils.handle_mappings will apply this <CR> mapping and any other custom mappings.
        return td_utils.handle_mappings(
          prompt_bufnr,
          map,
          require("docker_commands").config.mappings.system
        ) -- Access main config
      end,
    })
    :find()
end

-- system_entries is no longer exposed as it's read from the config directly

return M
