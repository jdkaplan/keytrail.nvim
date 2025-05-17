---@class KeyTrail
local M = {}

---@alias FileType 'yaml'|'json'

-- Default configuration
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
    delimiter = "→",    -- Right arrow
}

-- Configuration
local config = vim.deepcopy(default_config)

-- Create namespace for virtual text
local ns = vim.api.nvim_create_namespace('keytrail')

-- Set up highlight groups for each color
local function setup_highlights()
    -- Set up transparent background for the popup
    vim.api.nvim_set_hl(0, "KeyTrailPopup", {
        bg = "NONE",
        fg = "NONE",
    })

    -- Set up red color for delimiter
    vim.api.nvim_set_hl(0, "KeyTrailDelimiter", {
        fg = "#ff0000",  -- Bright red
        bold = false,
    })

    -- Set up blue color for array brackets
    vim.api.nvim_set_hl(0, "KeyTrailBracket", {
        fg = "#0000ff",  -- Bright blue
        bold = false,
    })

    for i, color in ipairs(config.colors) do
        vim.api.nvim_set_hl(0, "YAMLPathline" .. i, {
            fg = color,
            bold = false,
        })
    end
end

-- Track the current popup window and buffer
local current_popup = nil
local current_buf = nil

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
    -- If it's a number (array index), format it like jq
    if tonumber(segment) then
        return "[" .. segment .. "]"  -- This will be combined with the delimiter
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

        -- Handle both YAML and JSON object properties
        if type == "block_mapping_pair" or type == "flow_mapping_pair" or type == "pair" then
            local key_node = node:field("key")[1]
            if key_node then
                local key = clean_key(vim.treesitter.get_node_text(key_node, 0))
                table.insert(path, 1, key)
            end
        -- Handle both YAML and JSON array items
        elseif type == "block_sequence_item" or type == "flow_sequence_item" or type == "array" then
            local parent = node:parent()
            if parent then
                local index = 0
                for child in parent:iter_children() do
                    if child == node then break end
                    if child:type() == type then index = index + 1 end
                end
                table.insert(path, 1, "[" .. index .. "]")  -- Format array index with brackets
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
    end
    if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
        vim.api.nvim_buf_delete(current_buf, { force = true })
    end
    current_popup = nil
    current_buf = nil
end

-- Create a new popup window
local function create_popup()
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

    -- Create the popup window
    local popup = vim.api.nvim_open_win(buf, false, {
        relative = 'win',
        row = win_height - 2,  -- Just above status line
        col = 0,              -- Start from left edge
        width = win_width,    -- Full width to allow right alignment
        height = 1,
        style = 'minimal',
        border = 'none',
        noautocmd = true,
        focusable = false,
        zindex = 1,
    })

    -- Set popup window options
    vim.api.nvim_win_set_option(popup, 'winblend', 100)  -- Make window fully transparent
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

-- Show popup with path
local function show_popup()
    -- Always close existing popup first
    close_popup()

    local path = get_path()
    if path == "" then
        return
    end

    -- Split path into segments and create colored text
    local segments = vim.split(path, config.delimiter, { plain = true })
    local colored_text = {}

    for i, segment in ipairs(segments) do
        local color_idx = ((i - 1) % #config.colors) + 1
        
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
            table.insert(colored_text, { " → ", "KeyTrailDelimiter" })  -- Added spaces around the arrow
        end
    end

    -- Create new popup
    current_buf, current_popup = create_popup()

    -- Add virtual text with colors
    vim.api.nvim_buf_set_extmark(current_buf, ns, 0, 0, {
        virt_text = colored_text,
        virt_text_pos = "right_align",  -- Align to right edge
    })
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

    -- Start new timer
    hover_timer = vim.defer_fn(function()
        show_popup()
    end, config.hover_delay)
end

-- Set up autocommands
local function setup()
    local group = vim.api.nvim_create_augroup("KeyTrail", { clear = true })

    -- Show popup on cursor move
    vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
        group = group,
        callback = handle_cursor_move,
        pattern = { "*.yaml", "*.yml", "*.json" }
    })

    -- Clear popup when leaving buffer or window
    vim.api.nvim_create_autocmd({ "BufLeave", "WinLeave", "WinScrolled", "ModeChanged" }, {
        group = group,
        callback = function()
            if hover_timer then
                hover_timer:stop()
                hover_timer = nil
            end
            close_popup()
        end,
        pattern = { "*.yaml", "*.yml", "*.json" }
    })

    -- Clear popup when entering insert mode
    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
        group = group,
        callback = function()
            if hover_timer then
                hover_timer:stop()
                hover_timer = nil
            end
            close_popup()
        end,
        pattern = { "*.yaml", "*.yml", "*.json" }
    })
end

-- Initialize
setup()

-- Handler functions
function M.handle_cursor_move()
    show_popup()
end

function M.handle_window_change()
    show_popup()
end

function M.handle_buffer_change()
    show_popup()
end

-- Setup function
function M.setup(opts)
    if opts then
        config = vim.tbl_deep_extend('force', config, opts)
    end
    setup_highlights()
end

-- Export the module
return M
