# KeyTrail.nvim
A Neovim plugin in pure lua that shows the current path in YAML and JSON files, with the ability to jump to any path in the document using fuzzyfinding search w/ telescope / filepickers.

![Demo](docs/demo.gif)

## Features

- Shows the current path in YAML and JSON files
- Hover popup with the current path
- Jump to any path in the document using Telescope
- Support for both YAML and JSON file types
- Configurable delimiter and hover delay
- Customizable key mapping

## Requirements

- Neovim 0.9.0 or higher
- [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim)

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):

```lua
{
    "james1236/keytrail.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("keytrail").setup()
    end,
}
```

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use {
    "james1236/keytrail.nvim",
    requires = {
        "nvim-treesitter/nvim-treesitter",
        "nvim-telescope/telescope.nvim",
    },
    config = function()
        require("keytrail").setup()
    end,
}
```

## Configuration

KeyTrail can be configured by passing a table to the setup function:

```lua
require("keytrail").setup({
    -- The delimiter to use between path segments
    delimiter = ".",
    -- The delay in milliseconds before showing the hover popup
    hover_delay = 100,
    -- The key mapping to use for jumping to a path
    key_mapping = "jq",
    -- The file types to enable KeyTrail for
    filetypes = {
        yaml = true,
        json = true,
    },
})
```

## Usage

KeyTrail provides the following commands:

- `:KeyTrail <path>` - Jump to the specified path
- `:KeyTrailJump` - Open Telescope to select and jump to a path

By default, KeyTrail maps `<leader>jq` to `:KeyTrailJump` in normal mode.

