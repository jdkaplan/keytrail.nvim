local M = {}

local config = require('keytrail.config')

---Set up all highlight groups
function M.setup()
    -- Set up transparent background for the popup
    vim.api.nvim_set_hl(0, "KeyTrailPopup", {
        bg = "NONE",
        fg = "NONE",
    })

    -- Set up color for delimiter
    vim.api.nvim_set_hl(0, "KeyTrailDelimiter", {
        fg = config.get().delimiter_color,
        bold = false,
    })

    -- Set up color for array brackets
    vim.api.nvim_set_hl(0, "KeyTrailBracket", {
        fg = config.get().bracket_color,
        bold = false,
    })

    -- Set up colors for path segments
    for i, color in ipairs(config.get().colors) do
        vim.api.nvim_set_hl(0, "YAMLPathline" .. i, {
            fg = color,
            bold = false,
        })
    end
end

return M

