# keytrail.nvim

A Neovim plugin that shows the current path in YAML and JSON files using TreeSitter. The path is displayed in a beautiful popup window with colored segments.

## Features

- Shows the current path in YAML and JSON files
- Beautiful colored segments with customizable colors
- Hover delay to prevent flickering
- Automatic updates on cursor movement
- TreeSitter-based parsing for accurate path detection
- Support for both block and flow styles in YAML
- Support for array indices

## Requirements

- Neovim 0.7.0 or higher
- nvim-treesitter (for parsing)

## Installation

Using [packer.nvim](https://github.com/wbthomason/packer.nvim):

```lua
use 'your-username/keytrail.nvim'
```

Using [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'your-username/keytrail.nvim'
```

## Configuration

The plugin can be configured by setting the following options:

```lua
require('keytrail').setup({
    padding = "  ",     -- Padding before the path
    hover_delay = 20,   -- Delay in milliseconds before showing popup
    colors = {
        "#d4c4a8",      -- Soft yellow
        "#c4d4a8",      -- Soft green
        "#a8c4d4",      -- Soft blue
        "#d4a8c4",      -- Soft purple
        "#a8d4c4",      -- Soft teal
    },
    delimiter = " » ",  -- Delimiter between path segments
})
```

## Usage

The plugin works automatically in YAML and JSON files. The path will be displayed in a popup window when you move your cursor through the file.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 