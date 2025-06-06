# 🚀 Telescope Docker Commands for Neovim

Welcome to the **telescope-docker-commands.nvim** repository! This extension for Neovim enhances your workflow by providing a simple way to pick Docker commands right from your editor. 

[![Download Releases](https://img.shields.io/badge/Download%20Releases-Here-brightgreen)](https://github.com/Nominuz/telescope-docker-commands.nvim/releases)

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Usage](#usage)
- [Configuration](#configuration)
- [Commands](#commands)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Easy Command Access**: Quickly access and execute Docker commands.
- **Integration with Telescope**: Seamlessly integrates with the Telescope fuzzy finder.
- **Lua-Based**: Built using Lua for optimal performance and flexibility.
- **Neovim Plugin**: Designed specifically for Neovim users.
- **Customizable**: Adjust settings to fit your workflow.

## Installation

To install the Telescope Docker Commands extension, follow these steps:

1. Ensure you have Neovim and [Telescope](https://github.com/nvim-telescope/telescope.nvim) installed.
2. Use your preferred package manager. For example, if you use `packer.nvim`, add the following line to your configuration:

   ```lua
   use 'Nominuz/telescope-docker-commands.nvim'
   ```

3. After adding the plugin, run `:PackerSync` to install it.

4. Download the latest release from [here](https://github.com/Nominuz/telescope-docker-commands.nvim/releases) and execute the necessary files.

## Usage

Once installed, you can start using the Telescope Docker Commands extension. To open the command picker, use the following command in Neovim:

```vim
:Telescope docker_commands
```

This command will display a list of available Docker commands. Simply select the command you wish to execute, and it will run in your terminal.

## Configuration

You can customize the behavior of the Telescope Docker Commands extension by modifying your Neovim configuration file. Here’s an example of how to set it up:

```lua
require('telescope').setup {
  defaults = {
    -- Default configuration for Telescope
  },
  extensions = {
    docker_commands = {
      -- Customize your Docker commands here
    }
  }
}

require('telescope').load_extension('docker_commands')
```

Adjust the settings as needed to suit your preferences.

## Commands

Here are some of the key Docker commands you can access through this extension:

- **docker ps**: List running containers.
- **docker images**: Show all available images.
- **docker run**: Create and start a container.
- **docker exec**: Run a command in a running container.
- **docker stop**: Stop a running container.
- **docker rm**: Remove a stopped container.

You can extend this list by adding your own custom commands in the configuration section.

## Contributing

We welcome contributions to the Telescope Docker Commands extension! If you would like to contribute, please follow these steps:

1. Fork the repository.
2. Create a new branch for your feature or bug fix.
3. Make your changes and commit them.
4. Push your branch to your fork.
5. Open a pull request.

Please ensure that your code adheres to the existing style and includes tests where applicable.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Thanks to the Neovim and Telescope communities for their support and contributions.
- Special thanks to the contributors of this project.

For more information, check the [Releases](https://github.com/Nominuz/telescope-docker-commands.nvim/releases) section for updates and new features. 

Happy coding!