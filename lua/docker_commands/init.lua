local actions = require "telescope.actions"
local action_state = require "telescope.actions.state"
local td_utils = require "docker_commands.utils"

-- Define log for this module
local log = require("plenary.log").new {
  plugin = "docker_commands",
  level = "info",
}

-- Require picker modules
local containers_picker = require "docker_commands.pickers.containers"
local volumes_picker = require "docker_commands.pickers.volumes"
local images_picker = require "docker_commands.pickers.images"
local networks_picker = require "docker_commands.pickers.networks"
local system_picker = require "docker_commands.pickers.system"
local launcher_picker = require "docker_commands.pickers.launcher"

---@class TDConfig
---@field mappings table<string, table<string, {action: fun(prompt_bufnr: number, ...), desc: string}>>

---@class TDModule
---@field config TDConfig
---@field setup fun(TDConfig): TDModule
---@field docker_containers fun(opts?: table)
---@field docker_volumes fun(opts?: table)
---@field docker_images fun(opts?: table)
---@field docker_networks fun(opts?: table)
---@field docker_system fun(opts?: table)

local M = {}

--- Helper function to ensure configuration is loaded and call the picker
---@param picker_func fun(opts?: table) The actual picker function to call
---@param opts table|nil Optional arguments for the picker function
local function ensure_config_and_call_picker(picker_func, opts)
  -- Check if configuration is loaded, if not, load defaults and notify
  if not M.config or type(M.config.mappings) ~= "table" then
    vim.notify(
      "docker-commands.nvim configuration not loaded. Loading defaults. Please ensure require('docker_commands').setup({}) is called in your config.",
      vim.log.levels.WARN
    )
    M.setup({}) -- Load default configuration
  end
  picker_func(opts)
end

-- Default configuration
M.defaults = {
  -- Define available actions and their default keybindings
  -- For containers, images, volumes, and networks, actions are defined by command_args,
  -- identifier_field, and needs_confirmation. The actual action function is generated in setup.
  -- For system commands, the action function is defined directly as it calls run_system_command.
  actions = {
    containers = { -- Use the 'ID' field from the entry value
      select = {
        key = "<CR>",
        command_args = { "inspect" },
        identifier_field = "ID",
        needs_confirmation = false,
        desc = "Inspect Container",
      },
      interactive_shell = {
        key = "<C-i>",
        command_args = { "exec", "-it" },
        identifier_field = "ID",
        needs_confirmation = false,
        desc = "Container [I]nteractive shell",
      },
      logs = {
        key = "<C-l>",
        command_args = { "logs" },
        identifier_field = "ID",
        needs_confirmation = false,
        desc = "Container [L]ogs",
      },
      processes = {
        key = "<C-p>",
        command_args = { "top" },
        identifier_field = "ID",
        needs_confirmation = false,
        desc = "Container [P]rocesses",
      },
      stats = {
        key = "<C-s>",
        command_args = { "stats" },
        identifier_field = "ID",
        needs_confirmation = false,
        desc = "Container [S]tats",
      },
      remove = {
        key = "<C-r>",
        command_args = { "rm" },
        identifier_field = "ID",
        needs_confirmation = true,
        desc = "Container [R]emove",
      },
    },
    images = {
      select = {
        key = "<CR>",
        command_args = { "inspect" },
        identifier_field = "ID",
        needs_confirmation = false,
        desc = "Inspect Image",
      },
      history = {
        key = "<C-y>",
        command_args = { "history" },
        identifier_field = "ID",
        needs_confirmation = false,
        desc = "Image histor[Y]",
      },
      remove = {
        key = "<C-r>",
        command_args = { "rmi" },
        identifier_field = "ID",
        needs_confirmation = true,
        desc = "Image [R]emove",
      },
    },
    volumes = { -- Use the 'Name' field from the entry value
      select = {
        key = "<CR>",
        command_args = { "volume", "inspect" },
        identifier_field = "Name",
        needs_confirmation = false,
        desc = "Inspect Volume",
      },
      remove = {
        key = "<C-r>",
        command_args = { "volume", "rm" },
        identifier_field = "Name",
        needs_confirmation = true,
        desc = "Volume [R]emove",
      },
    },
    networks = { -- Use the 'ID' field from the entry value
      select = {
        key = "<CR>",
        command_args = { "network", "inspect" },
        identifier_field = "ID",
        needs_confirmation = false,
        desc = "Inspect Network",
      },
      remove = { -- Added remove action for networks
        key = "<C-r>",
        command_args = { "network", "rm" },
        identifier_field = "ID",
        needs_confirmation = true,
        desc = "Network [R]emove",
      },
    },
    system = {
      -- All items in system picker execute the action on selection (<CR>)
      df = {
        command_args = { "system", "df" },
        display = "Show Docker disk usage",
        needs_confirmation = false,
        order = 10,
        desc = "Show Docker disk usage",
      },
      system_prune = {
        command_args = { "system", "prune" },
        display = "Remove unused containers, networks, images, and volumes",
        needs_confirmation = true,
        order = 20,
        desc = "System Prune",
      },
      system_prune_a = {
        command_args = { "system", "prune", "-a" },
        display = "Aggressive cleanup: includes all unused images, networks, and build cache",
        needs_confirmation = true,
        order = 30,
        desc = "System Prune (Aggressive)",
      },
      builder_prune = {
        command_args = { "builder", "prune" },
        display = "Remove dangling build cache",
        needs_confirmation = true,
        order = 40,
        desc = "Builder Prune",
      },
      builder_prune_a = {
        command_args = { "builder", "prune", "-a" },
        display = "Aggressive Remove dangling build cache",
        needs_confirmation = true,
        order = 50,
        desc = "Builder Prune (Aggressive)",
      },
      container_prune = {
        command_args = { "container", "prune" },
        display = "Remove stopped containers",
        needs_confirmation = true,
        order = 60,
        desc = "Container Prune",
      },
      image_prune = {
        command_args = { "image", "prune" },
        display = "Remove unused images",
        needs_confirmation = true,
        order = 70,
        desc = "Image Prune",
      },
      image_prune_a = {
        command_args = { "image", "prune", "-a" },
        display = "Remove all unused images, not just dangling",
        needs_confirmation = true,
        order = 80,
        desc = "Image Prune (Aggressive)",
      },
      volume_prune = {
        command_args = { "volume", "prune" },
        display = "Remove unused volumes",
        needs_confirmation = true,
        order = 90,
        desc = "Volume Prune",
      },
      network_prune = {
        command_args = { "network", "prune" },
        display = "Remove all unused user-defined networks",
        needs_confirmation = true,
        order = 100,
        desc = "Network Prune",
      },
    },
  },

}

-- Current configuration (will be merged with defaults in setup)
M.config = {}

---@param config TDConfig
M.setup = function(config)
  -- Start with a deep copy of defaults
  M.config = vim.deepcopy(M.defaults)

  -- Apply user config using deep extend. This merges non-action config and overrides default action definitions.
  M.config = vim.tbl_deep_extend("force", M.config, config or {})

  -- Now, rebuild the mappings structure based on the merged actions (M.config.actions)
  M.config.mappings = {}

  if M.config.actions then
    for picker_type, actions_config in pairs(M.config.actions) do
      M.config.mappings[picker_type] = {} -- Initialize mappings table for this picker type

      if picker_type == "system" then
        -- For the system picker, the <CR> action executes the selected command.
        -- We define this single action here and map it to <CR> in the mappings table.
        local system_cr_action_func = function(prompt_bufnr)
          local selection = action_state.get_selected_entry()
          actions.close(prompt_bufnr)
          -- Get command_args and confirmation from the selected entry's value
          if selection and selection.value and selection.value.command_args then
            td_utils.run_system_command(selection.value.command_args, selection.value.needs_confirmation or false)
          else
            log.warn("System picker <CR> action (generated in setup): Invalid selection or missing command_args in selection value.", vim.inspect(selection))
            vim.notify("Could not execute command: Invalid selection.", vim.log.levels.ERROR)
          end
        end
        -- Add this action to the mappings for the system picker under the <CR> key
        M.config.mappings[picker_type]["<CR>"] = {
          action = system_cr_action_func,
          desc = "Execute System Command", -- Default description for the <CR> action
        }
        -- No need to iterate over individual system commands in actions_config here,
        -- as they don't have individual key mappings within the picker.
      else
        -- For other picker types (containers, images, etc.), iterate over actions_config
        -- and generate mappings based on the 'key' field.
        if actions_config then
          for action_name, action_data in pairs(actions_config) do
            -- Ensure action_data is a valid table and has a key
            if type(action_data) == "table" and action_data.key and action_data.key ~= "" then
              local action_func
              -- Generate action function for non-system pickers
              if action_data.command_args and action_data.identifier_field then
                action_func = function(prompt_bufnr)
                  local selection = action_state.get_selected_entry()
                  actions.close(prompt_bufnr)
                  local entry_value = selection.value
                  local identifier = entry_value[action_data.identifier_field]
                  local needs_confirmation = action_data.needs_confirmation or false
                  td_utils.run_object_command(action_data.command_args, entry_value, identifier, needs_confirmation)
                end
              else

                log.warn(
                  string.format(
                    "Incomplete action configuration for picker '%s', action '%s'. Missing command_args or identifier_field.",
                    picker_type,
                    action_name
                  )
                )
                action_func = function()
                  vim.notify(
                    string.format(
                      "Action '%s' for picker '%s' is misconfigured.",
                      action_name,
                      picker_type
                    ),
                    vim.log.levels.ERROR
                  )
                end
              end
              -- Add the generated action function to the mappings table
              M.config.mappings[picker_type][action_data.key] = {
                action = action_func,
                desc = action_data.desc or "",
              }
            end -- end if action_data is valid
          end -- end for actions_config
        end -- end if actions_config
      end -- end if picker_type == "system"
    end -- end for picker_type
  end -- end if M.config.actions

  -- log.info("Final Telescope Docker commands configuration:", vim.inspect(M.config.mappings))
end

-- Expose picker functions from their respective modules, wrapped with the config check
M.docker_containers = function(opts)
  ensure_config_and_call_picker(containers_picker.docker_containers, opts)
end
M.docker_volumes = function(opts)
  ensure_config_and_call_picker(volumes_picker.docker_volumes, opts)
end
M.docker_images = function(opts)
  ensure_config_and_call_picker(images_picker.docker_images, opts)
end
M.docker_networks = function(opts)
  ensure_config_and_call_picker(networks_picker.docker_networks, opts)
end
M.docker_system = function(opts)
  ensure_config_and_call_picker(system_picker.docker_system, opts)
end
M.docker_launcher = function(opts)
  ensure_config_and_call_picker(launcher_picker.docker_launcher, opts)
end

return M
