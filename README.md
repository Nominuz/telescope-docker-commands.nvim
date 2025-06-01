# Telescope Docker commands plugin

Docker commands picker for Neovim, built as an extension on Telescope.

## Installation

Use your favourite plugin manager, e.g.:

```lua
{
  'zigotica/telescope-docker-commands.nvim',
   event = 'VeryLazy',
   dependencies = {
     'nvim-lua/plenary.nvim',
     'nvim-telescope/telescope.nvim',
   },
}
```

## Setup

First, load the extension. This is normally used after all telescope setup:

```lua
require("telescope").load_extension("docker_commands")
```

Now it's time for the plugin setup, that allows us to basically change the keymaps, actions and descriptions for each specified key action name:

```lua
require("docker_commands").setup({
  -- Overwrite/Extend actions for each picker
  -- Actions are defined as tables containing command details,
  -- not direct functions, allowing for easier customization.
  actions = {
    -- Actions are categorized by main pickers
    containers = {
      -- Each action is referenced by a "key" action name, so it is easier to remap.
      -- Example: Customize the 'logs' action
      logs = {
        key = "<C-g>", -- change from C-l to C-g
        command_args = { "logs", "-f" }, -- add the -f to follow logs in real time
        desc = "Container lo[G]s", -- this will be shown in telescope keymaps help
        -- You dont need to modify all table
      },
      -- You can also add new key actions
      kill = {
        key = "<C-k>",
        command_args = { "kill" },
        identifier_field = "ID",
        needs_confirmation = true,
        desc = "[K]ill Container",
      },
    },
    images = {},
    networks = {},
    volumes = {},
    -- System actions are all executed by selecting (<CR>), no key needed
    -- The construction is a bit different than other pickers:
    system = {
      builder_prune_a = {
        order = 1,
        command_args = { "builder", "prune", "-a" },
        display = "Aggressive Remove dangling build cache",
        needs_confirmation = true,
        desc = "Builder Prune (Aggressive)",
      },
    },
  },
})
```

There is a launch picker that lists the other pickers. The specific pickers are divided by type: container, image, volume, network, system.

### Containers Picker default Actions

The list of containers is generated using the `docker ps -a` command.

| Action            | Keymap  | Action Name         | Description                   |
| :---------------- | :------ | :------------------ | :---------------------------- |
| Inspect           | `<CR>`  | `select`            | Inspect Container             |
| Interactive Shell | `<C-i>` | `interactive_shell` | Container [I]nteractive shell |
| Logs              | `<C-l>` | `logs`              | Container [L]ogs              |
| Processes         | `<C-p>` | `processes`         | Container [P]rocesses         |
| Stats             | `<C-s>` | `stats`             | Container [S]tats             |
| Remove            | `<C-r>` | `remove`            | Container [R]emove            |

### Images Picker default Actions

The list of images is generated using the `docker images` command.

| Action  | Keymap  | Action Name | Description     |
| :------ | :------ | :---------- | :-------------- |
| Inspect | `<CR>`  | `select`    | Inspect Image   |
| History | `<C-y>` | `history`   | Image histor[Y] |
| Remove  | `<C-r>` | `remove`    | Image [R]emove  |

### Volumes Picker default Actions

The list of volumes is generated using the `docker volume ls` command.

| Action  | Keymap  | Action Name | Description     |
| :------ | :------ | :---------- | :-------------- |
| Inspect | `<CR>`  | `select`    | Inspect Volume  |
| Remove  | `<C-r>` | `remove`    | Volume [R]emove |

### Networks Picker default Actions

The list of networks is generated using the `docker network ls` command.

| Action  | Keymap  | Action Name | Description      |
| :------ | :------ | :---------- | :--------------- |
| Inspect | `<CR>`  | `select`    | Inspect Network  |
| Remove  | `<C-r>` | `remove`    | Network [R]emove |

### System Picker Actions

This picker lists common Docker system commands.

| Command                 | Keymap | Description                                                               |
| :---------------------- | :----- | :------------------------------------------------------------------------ |
| docker system df        | `<CR>` | Show Docker disk usage                                                    |
| docker system prune     | `<CR>` | Remove unused containers, networks, images, and volumes                   |
| docker system prune -a  | `<CR>` | Aggressive cleanup: includes all unused images, networks, and build cache |
| docker builder prune    | `<CR>` | Remove dangling build cache                                               |
| docker builder prune -a | `<CR>` | Aggressive Remove dangling build cache                                    |
| docker container prune  | `<CR>` | Remove stopped containers                                                 |
| docker image prune      | `<CR>` | Remove unused images                                                      |
| docker image prune -a   | `<CR>` | Aggressive Remove all unused images, not just dangling                    |
| docker volume prune     | `<CR>` | Remove unused volumes                                                     |
| docker network prune    | `<CR>` | Remove all unused user-defined networks                                   |

## Trigger launcher picker

You can run `:Telescope docker_commands` or add your own keymap to trigger the plugin (I do not provide any, choose your own). e.g.:

```lua
vim.keymap.set("n", "<leader>dk", ":Telescope docker_commands<CR>", { desc = "[D]oc[K]er Actions picker" })
```

## Inspiration

Based on the source code of the demo video that explains how to create a Telescope extension: [telescope-docker](https://github.com/krisajenkins/telescope-docker.nvim) by [Kris Jenkins](https://github.com/krisajenkins)
