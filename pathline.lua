---@class YAMLPathline
local M = {}

---@alias FileType 'yaml'|'json'

-- Configuration
local config = {
    padding = "  ",     -- Reduced padding to 2 spaces
    hover_delay = 20,   -- Delay in milliseconds before showing popup
    colors = {
        "#d4c4a8",      -- Soft yellow
        "#c4d4a8",      -- Soft green
        "#a8c4d4",      -- Soft blue
        "#d4a8c4",      -- Soft purple
        "#a8d4c4",      -- Soft teal
    },
    delimiter = " » ",
}

-- Create namespace for virtual text
local ns = vim.api.nvim_create_namespace('yaml_pathline')

-- Set up highlight groups for each color
for i, color in ipairs(config.colors) do
    vim.api.nvim_set_hl(0, "YAMLPathline" .. i, {
        fg = color,
        bold = false,
    })
end

-- Track the current popup window
local current_popup = nil

-- Ensure TreeSitter parser is installed and working
---@param lang FileType
---@return boolean
local function ensure_parser_ready(lang)
    local ok, parsers = pcall(require, 'nvim-treesitter.parsers')
    if not ok then
        vim.notify("yaml_pathline: nvim-treesitter not available", vim.log.levels.WARN)
        return false
    end

    local parser_config = parsers.get_parser_configs()[lang]
    if not parser_config then
        vim.notify("yaml_pathline: No parser config for " .. lang, vim.log.levels.WARN)
        return false
    end

    if not parsers.has_parser(lang) then
        vim.schedule(function()
            vim.cmd('TSInstall ' .. lang)
        end)
        vim.notify("yaml_pathline: Installing " .. lang .. " parser...", vim.log.levels.INFO)
        return false
    end

    return true
end

-- Helper: extract key from node text
---@param key string
---@return string
local function clean_key(key)
    return key:gsub('^["\']', ''):gsub('["\']$', '')
end

-- Helper: format path segment
---@param segment string
---@return string
local function format_segment(segment)
    -- If it's a number (array index), wrap it in square brackets
    if tonumber(segment) then
        return "[" .. segment .. "]"
    end
    return segment
end

---@param ft FileType
---@return string|nil
local function get_treesitter_path(ft)
    if not ensure_parser_ready(ft) then
        return nil
    end

    local ok_parser, parser = pcall(vim.treesitter.get_parser, 0, ft)
    if not ok_parser or not parser then
        return nil
    end

    local trees = parser:parse()
    if not trees or not trees[1] then
        return nil
    end

    local tree = trees[1]
    local root = tree:root()
    if not root then
        return nil
    end

    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]
    local node = root:named_descendant_for_range(row, col, row, col)
    if not node then
        return nil
    end

    ---@type string[]
    local path = {}
    while node do
        local type = node:type()

        if type == "block_mapping_pair" or type == "flow_mapping_pair" then
            local key_node = node:field("key")[1]
            if key_node then
                local key = clean_key(vim.treesitter.get_node_text(key_node, 0))
                table.insert(path, 1, format_segment(key))
            end
        elseif type == "block_sequence_item" or type == "flow_sequence_item" then
            local parent = node:parent()
            if parent then
                local index = 0
                for child in parent:iter_children() do
                    if child == node then break end
                    if child:type() == type then index = index + 1 end
                end
                table.insert(path, 1, tostring(index))
            end
        end

        node = node:parent()
    end

    if #path == 0 then
        return nil
    end

    -- Join path segments with a beautiful delimiter
    return table.concat(path, config.delimiter)
end

-- Entry point
---@return string
local function get_path()
    local ft = vim.bo.filetype
    if ft ~= "yaml" and ft ~= "json" then
        return ""
    end

    local path = get_treesitter_path(ft)
    if not path then
        return ""
    end

    -- Add padding and prefix
    return config.padding .. path
end

-- Close the current popup if it exists
local function close_popup()
    if current_popup and vim.api.nvim_win_is_valid(current_popup) then
        vim.api.nvim_win_close(current_popup, true)
        current_popup = nil
    end
end

-- Show popup with path
local function show_popup()
    local path = get_path()
    if path == "" then
        close_popup()
        return
    end

    -- Split path into segments and create colored text
    local segments = vim.split(path, config.delimiter, { plain = true })
    local colored_text = {}

    for i, segment in ipairs(segments) do
        local color_idx = ((i - 1) % #config.colors) + 1
        table.insert(colored_text, { segment, "YAMLPathline" .. color_idx })
        if i < #segments then
            table.insert(colored_text, { config.delimiter, "YAMLPathline1" })   -- Use first color for delimiter
        end
    end

    -- Create a new buffer for the popup
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "" })   -- Empty line to hold virtual text
    vim.api.nvim_buf_set_option(buf, 'modifiable', false)
    vim.api.nvim_buf_set_option(buf, 'modified', false)
    vim.api.nvim_buf_set_option(buf, 'buftype', 'nofile')
    vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
    vim.api.nvim_buf_set_option(buf, 'swapfile', false)

    -- Get window dimensions
    local win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)
    local popup_width = #path + 1
    local popup_height = 1

    -- Position the popup in the bottom right
    local popup_row = win_height - 3
    local popup_col = win_width - popup_width - 2

    -- Create the popup window
    local popup = vim.api.nvim_open_win(buf, false, {
        relative = 'win',
        row = popup_row,
        col = popup_col,
        width = popup_width,
        height = popup_height,
        style = 'minimal',
        border = 'none',
        noautocmd = true,
        focusable = false,   -- Make window non-focusable
        zindex = 1,          -- Keep it below other UI elements
    })

    -- Set popup window options
    vim.api.nvim_win_set_option(popup, 'winblend', 0)
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

    -- Add virtual text with colors
    vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
        virt_text = colored_text,
        virt_text_pos = "overlay",
    })

    -- Store the popup window reference
    current_popup = popup
end

-- Timer for hover delay
local hover_timer = nil

-- Handle cursor movement
local function handle_cursor_move()
    -- Clear existing timer
    if hover_timer then
        hover_timer:stop()
        hover_timer = nil
    end

    -- Always close existing popup on move
    close_popup()

    -- Start new timer
    hover_timer = vim.defer_fn(function()
        show_popup()
    end, config.hover_delay)
end

-- Set up autocommands
local function setup()
    local group = vim.api.nvim_create_augroup("YAMLPathline", { clear = true })

    -- Show popup on cursor move
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        callback = handle_cursor_move,
        pattern = { "*.yaml", "*.yml", "*.json" }
    })

    -- Clear popup when leaving buffer or window
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "WinScrolled", "ModeChanged" }, {
        group = group,
        callback = close_popup,
        pattern = { "*.yaml", "*.yml", "*.json" }
    })

    -- Clear popup when entering insert mode
    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
        group = group,
        callback = close_popup,
        pattern = { "*.yaml", "*.yml", "*.json" }
    })
end

-- Initialize
setup()

-- Export only what's needed
M.setup = setup
M.show = show_popup
M.hide = close_popup

return M
