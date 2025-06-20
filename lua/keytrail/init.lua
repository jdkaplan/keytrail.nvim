---@class KeyTrail
local M = {}

---@alias FileType 'yaml'|'json'
local config = require('keytrail.config')
local popup = require('keytrail.popup')
local highlights = require('keytrail.highlights')
local jump = require('keytrail.jump')

-- Timer for hover delay
local hover_timer = nil

---@param lang string
---@return boolean
local function ensure_parser_ready(lang)
    local ok, parsers = pcall(require, 'nvim-treesitter.parsers')
    if not ok then
        vim.notify("yaml_pathline: nvim-treesitter not available", vim.log.levels.WARN)
        return false
    end

    -- Check if using new treesitter (get_parser_configs returns nil)
    if not parsers or not parsers.get_parser_configs then
        return true
    end

    local parser_configs = parsers.get_parser_configs()
    local parser_config = parser_configs[lang]
    if not parser_config then
        vim.notify("yaml_pathline: No parser config for " .. lang, vim.log.levels.WARN)
        return false
    end

    -- Check if the parser is installed
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
local function clean_key(key)
    return key:gsub('^["\']', ''):gsub('["\']$', '')
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
                table.insert(path, 1, "[" .. index .. "]") -- Format array index with brackets
            end
        end

        node = node:parent()
    end

    if #path == 0 then
        return nil
    end

    -- Join path segments with a beautiful delimiter
    return table.concat(path, config.get().delimiter)
end

-- Entry point
---@return string
local function get_path()
    local ft = vim.bo.filetype
    if not config.get().filetypes[ft] then
        return ""
    end

    local path = get_treesitter_path(ft)
    if not path then
        return ""
    end

    return path
end

-- Handle cursor movement
local function handle_cursor_move()
    -- Clear existing timer
    if hover_timer then
        hover_timer:stop()
        hover_timer = nil
    end

    -- Start new timer
    hover_timer = vim.defer_fn(function()
        popup.show(get_path())
    end, config.get().hover_delay)
end

-- Helper function to clear hover timer
local function clear_hover_timer()
    if hover_timer then
        hover_timer:stop()
        hover_timer = nil
    end
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
            clear_hover_timer()
            popup.close()
        end,
        pattern = { "*.yaml", "*.yml", "*.json" }
    })

    -- Clear popup when entering insert mode
    vim.api.nvim_create_autocmd({ "InsertEnter" }, {
        group = group,
        callback = function()
            clear_hover_timer()
            popup.close()
        end,
        pattern = { "*.yaml", "*.yml", "*.json" }
    })
end

-- Generic handler function for all events
local function handle_event()
    popup.show(get_path())
end

-- Handler functions
M.handle_cursor_move = handle_event
M.handle_window_change = handle_event
M.handle_buffer_change = handle_event

-- Setup function
function M.setup(opts)
    -- Prevent double setup
    if M._setup then
        return
    end
    M._setup = true

    -- Ensure leader key is set
    if vim.g.mapleader == nil then
        vim.g.mapleader = " "
    end

    if opts ~= nil then
        config.set(opts)
    end
    highlights.setup()
    setup()

    -- Create the KeyTrail command
    vim.api.nvim_create_user_command('KeyTrail', function(opts)
        local ft = vim.bo.filetype
        if not config.get().filetypes[ft] then
            vim.notify("KeyTrail: Current filetype not supported", vim.log.levels.ERROR)
            return
        end

        if not opts.args or opts.args == "" then
            vim.notify("KeyTrail: Please provide a path to jump to", vim.log.levels.ERROR)
            return
        end

        if not jump.jump_to_path(ft, opts.args) then
            vim.notify("KeyTrail: Could not find path: " .. opts.args, vim.log.levels.ERROR)
        end
    end, {
        nargs = 1,
        complete = function()
            -- TODO: Add completion for valid paths
            return {}
        end
    })

    -- Create the KeyTrailJump command
    vim.api.nvim_create_user_command('KeyTrailJump', function()
        local ft = vim.bo.filetype
        if not config.get().filetypes[ft] then
            vim.notify("KeyTrail: Current filetype not supported", vim.log.levels.ERROR)
            return
        end

        if not jump.jumpwindow() then
            vim.notify("KeyTrail: Could not jump to specified path", vim.log.levels.ERROR)
        end
    end, {})

    -- Set up default key mapping
    vim.keymap.set('n', '<leader>' .. config.get().key_mapping, function()
        local ft = vim.bo.filetype
        if not config.get().filetypes[ft] then
            vim.notify("KeyTrail: Current filetype not supported", vim.log.levels.ERROR)
            return
        end
        jump.jumpwindow()
    end, { desc = 'KeyTrail: Jump to path', silent = true })
end

return M
