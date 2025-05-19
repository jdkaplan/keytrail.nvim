local M = {}

---@class KeyTrailConfig
local default_config = {
    padding = "  ",     -- Reduced padding to 2 spaces
    hover_delay = 20,   -- Delay in milliseconds before showing popup
    colors = {
        "#d4c4a8",      -- Soft yellow
        "#c4d4a8",      -- Soft green
        "#a8c4d4",      -- Soft blue
        "#d4a8c4",      -- Soft purple
        "#a8d4c4",      -- Soft teal
    },
    delimiter = ".",    -- Dot as default delimiter
    position = "bottom", -- Position of the popup
    zindex = 1,         -- z-index of the popup window
    bracket_color = "#0000ff", -- Blue color for brackets
    delimiter_color = "#ff0000", -- Red color for delimiter
    filetypes = {       -- Supported file types
        yaml = true,
        json = true
    }
}

---@type KeyTrailConfig
local config = vim.deepcopy(default_config)

---Get the current configuration
---@return KeyTrailConfig
function M.get()
    return config
end

---Update the configuration
---@param opts KeyTrailConfig
function M.set(opts)
    if not opts then return end
    -- Only merge fields that are provided in opts
    for k, v in pairs(opts) do
        if type(v) == "table" and type(config[k]) == "table" then
            config[k] = vim.tbl_deep_extend('force', config[k], v)
        else
            config[k] = v
        end
    end
end

---Reset the configuration to defaults
function M.reset()
    config = vim.deepcopy(default_config)
end

return M 