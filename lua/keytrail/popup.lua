local M = {}

local config = require('keytrail.config')

-- Create namespace for virtual text
local ns = vim.api.nvim_create_namespace('keytrail')

-- Track the current popup window and buffer
local current_popup = nil
local current_buf = nil

---Close the current popup if it exists
function M.close()
    if current_popup and vim.api.nvim_win_is_valid(current_popup) then
        vim.api.nvim_win_close(current_popup, true)
    end
    if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
        vim.api.nvim_buf_delete(current_buf, { force = true })
    end
    current_popup = nil
    current_buf = nil
end

---Create a new popup window
---@return number, number The buffer and window IDs
function M.create()
    -- Create a new buffer
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'modified', false)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)

    -- Get window dimensions
    local win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)

    -- Calculate popup position
    local row = config.get().position == "bottom" and win_height - 2 or 0

    -- Create the popup window
    local popup = vim.api.nvim_open_win(buf, false, {
        relative = 'win',
        row = row,
        col = 0,
        width = win_width,
        height = 1,
        style = 'minimal',
        border = 'none',
        noautocmd = true,
        focusable = false,
        zindex = config.get().zindex,
    })

    -- Set popup window options
    vim.api.nvim_win_set_option(popup, 'winblend', 100)
    vim.api.nvim_win_set_option(popup, 'cursorline', false)
    vim.api.nvim_win_set_option(popup, 'cursorcolumn', false)
    vim.api.nvim_win_set_option(popup, 'number', false)
    vim.api.nvim_win_set_option(popup, 'relativenumber', false)
    vim.api.nvim_win_set_option(popup, 'signcolumn', 'no')
    vim.api.nvim_win_set_option(popup, 'foldcolumn', '0')
    vim.api.nvim_win_set_option(popup, 'list', false)
    vim.api.nvim_win_set_option(popup, 'wrap', false)
    vim.api.nvim_win_set_option(popup, 'linebreak', false)
    vim.api.nvim_win_set_option(popup, 'scrolloff', 0)
    vim.api.nvim_win_set_option(popup, 'sidescrolloff', 0)

    -- Set the window highlight to transparent
    vim.api.nvim_win_set_hl_ns(popup, ns)
    vim.api.nvim_win_set_option(popup, 'winhighlight', 'Normal:KeyTrailPopup')

    return buf, popup
end

---Show the popup with the given path
---@param path string The path to display
function M.show(path)
    -- Always close existing popup first
    M.close()

    if path == "" then
        return
    end

    -- Split path into segments and create colored text
    local segments = vim.split(path, config.get().delimiter, { plain = true })
    local colored_text = {}

    for i, segment in ipairs(segments) do
        local color_idx = ((i - 1) % #config.get().colors) + 1
        
        -- Handle array indices with blue brackets
        if segment:match("^%[.*%]$") then
            local index = segment:match("%[(%d+)%]")
            table.insert(colored_text, { "[", "KeyTrailBracket" })
            table.insert(colored_text, { index, "YAMLPathline" .. color_idx })
            table.insert(colored_text, { "]", "KeyTrailBracket" })
        else
            table.insert(colored_text, { segment, "YAMLPathline" .. color_idx })
        end
        
        -- Add delimiter if not the last segment
        if i < #segments then
            table.insert(colored_text, { " → ", "KeyTrailDelimiter" })
        end
    end

    -- Create new popup
    current_buf, current_popup = M.create()

    -- Add virtual text with colors
    vim.api.nvim_buf_set_extmark(current_buf, ns, 0, 0, {
        virt_text = colored_text,
        virt_text_pos = "right_align",
    })
end

return M 