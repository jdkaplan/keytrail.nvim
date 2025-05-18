# keytrail.nvim

A Neovim plugin that shows the path to the current cursor position in YAML and JSON files using TreeSitter.

![Demo](docs/demo.gif)

## Features

- Shows the object path at cursor for `yaml`, `json`
- Uses TreeSitter for accurate parsing
- Supports array indices
- Transparent and non intrusive path line
- Configurable position, colors, delimiter for path line.

## Requirements

- Neovim 0.9.0 or higher
- TreeSitter parser for YAML and JSON

## Installation

### Using Lazy.nvim

Add this to your Neovim configuration:

```lua
{
    "JFryy/keytrail.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        require('keytrail').setup({
            -- Configuration options
            padding = "  ",     -- Space around the popup
            hover_delay = 20,   -- Delay in milliseconds before showing popup
            colors = {
                "#d4c4a8",      -- Soft yellow
                "#c4d4a8",      -- Soft green
                "#a8c4d4",      -- Soft blue
                "#d4a8c4",      -- Soft purple
                "#a8d4c4",      -- Soft teal
            },
            delimiter = "→",    -- Path segment separator
            position = "bottom", -- Popup position ("top" or "bottom")
            zindex = 1,         -- Window z-index
            bracket_color = "#0000ff", -- Color for array brackets
            delimiter_color = "#ff0000", -- Color for path delimiters
            filetypes = {
                yaml = true,
                json = true
            }
        })
    end
}
```

Make sure you have TreeSitter parsers installed:
```lua
:TSInstall yaml json
```

## Configuration

The plugin can be configured through the `setup` function. Here are all available options:

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `padding` | string | `"  "` | Space around the popup |
| `hover_delay` | number | `20` | Delay in milliseconds before showing popup |
| `colors` | string[] | `["#d4c4a8", "#c4d4a8", "#a8c4d4", "#d4a8c4", "#a8d4c4"]` | Array of colors for path segments |
| `delimiter` | string | `"→"` | Path segment separator |
| `position` | string | `"bottom"` | Popup position ("top" or "bottom") |
| `zindex` | number | `1` | Window z-index |
| `bracket_color` | string | `"#0000ff"` | Color for array brackets |
| `delimiter_color` | string | `"#ff0000"` | Color for path delimiters |
| `filetypes` | table | `{ yaml = true, json = true }` | Supported file types |

