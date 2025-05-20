# KeyTrail.nvim

A Neovim plugin for navigating YAML and JSON files using path-like syntax. KeyTrail provides an intuitive way to jump to specific locations in your YAML and JSON files, similar to how you might navigate a file system.
![Demo](docs/demo.gif)

## Features

- Navigate YAML and JSON files using path-like syntax
- Support for array indexing (e.g., `data[0].key`)
- Interactive jump window with autocomplete
- Configurable delimiter for path segments
- TreeSitter-based parsing for accurate navigation

## Requirements

- Neovim 0.9.0 or higher
- TreeSitter parser for YAML and JSON:
  ```vim
  :TSInstall yaml
  :TSInstall json
  ```

## Installation

Using [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
    "jfryy/keytrail.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        require("keytrail").setup()
    end
}
```


Using [lazy.nvim](https://github.com/folke/lazy.nvim) -- defaults visible
```lua
{
    "jfryy/keytrail.nvim",
    dependencies = {
        "nvim-treesitter/nvim-treesitter",
    },
    config = function()
        require("keytrail").setup({
            -- Default configuration, you probably don't want to include all of this.
            -- Delay in milliseconds before showing popup (default: 20)
            --    hover_delay = 20,

            -- Array of colors for path segments (default: soft pastel colors)
            -- colors = {
            --     "#d4c4a8", -- Soft yellow
            --     "#c4d4a8", -- Soft green
            --     "#a8c4d4", -- Soft blue
            --     "#d4a8c4", -- Soft purple
            --     "#a8d4c4", -- Soft teal
            -- },

            -- Path segment separator (default: ".")
            -- delimiter = ".",

            -- Position of the popup (default: "bottom")
            -- Options: "top", "bottom"
            -- position = "bottom",

            -- Z-index of the popup window (default: 1)
            -- zindex = 1,

            -- Color for array brackets (default: "#0000ff")
            -- bracket_color = "#0000ff",

            -- Color for path delimiters (default: "#ff0000")
            -- delimiter_color = "#ff0000",

            -- Supported file types (default: { yaml = true, json = true })
            -- filetypes = {
            --     yaml = true,
            --     json = true,
            -- },

            -- Key mapping for jump window (default: "jq")
            -- Will be prefixed with <leader>
            -- key_mapping = "jq",

        })
    end,
}
```

## Usage

KeyTrail provides two main ways to navigate your YAML and JSON files:

### 1. Command Line

Use the `:KeyTrail` command followed by a path:

```vim
:KeyTrail data[0].key
```

### 2. Interactive Jump Window

Use the default mapping `<leader>jq` to open an interactive jump window at your cursor position. This window provides:
- A clean, floating input field
- Enter to jump to the specified path
- Esc to cancel
- Automatic positioning relative to your cursor

### Default Mappings

KeyTrail sets up the following default mapping:

- `<leader>jq` - Open the interactive jump window

You can customize this mapping in your configuration.

## Examples

### YAML Navigation

```yaml
data:
  users:
    - name: John
      age: 30
    - name: Jane
      age: 25
  settings:
    theme: dark
    language: en
```

Navigate using paths like:
- `data.users[0].name` → Jumps to "John"
- `data.settings.theme` → Jumps to "dark"

### JSON Navigation

```json
{
  "data": {
    "users": [
      {
        "name": "John",
        "age": 30
      },
      {
        "name": "Jane",
        "age": 25
      }
    ],
    "settings": {
      "theme": "dark",
      "language": "en"
    }
  }
}
```

Navigate using paths like:
- `data.users[0].name` → Jumps to "John"
- `data.settings.theme` → Jumps to "dark"

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.


