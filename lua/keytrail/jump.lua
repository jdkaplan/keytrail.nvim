local M = {}
local config = require('keytrail.config')

-- Helper: extract key from node text
---@param key string
local function clean_key(key)
    return key:gsub('^["\']', ''):gsub('["\']$', '')
end

---Find a node by its path in the document
---@param ft string The file type
---@param path string The path to find (e.g. "data[0].key1")
---@return boolean success Whether the jump was successful
function M.jump_to_path(ft, path)
    local ok_parser, parser = pcall(vim.treesitter.get_parser, 0, ft)
    if not ok_parser or not parser then
        return false
    end

    local trees = parser:parse()
    if not trees or not trees[1] then
        return false
    end

    local tree = trees[1]
    local root = tree:root()
    if not root then
        return false
    end

    -- Split path into segments
    local segments = vim.split(path, config.get().delimiter, { plain = true })
    local current_node = root

    -- Traverse the path
    for _, segment in ipairs(segments) do
        local found = false
        -- Check if segment is an array index
        local index = segment:match("%[(%d+)%]")
        local key = segment:match("^([^%[]+)%[")

        -- Handle YAML document structure
        if current_node:type() == "stream" then
            for child in current_node:iter_children() do
                if child:type() == "document" then
                    current_node = child
                    break
                end
            end
        end

        if current_node:type() == "document" then
            for child in current_node:iter_children() do
                if child:type() == "block_node" or child:type() == "block_mapping" then
                    current_node = child
                    break
                end
            end
        end

        -- If we're at a block_node, get its block_mapping child
        if current_node:type() == "block_node" then
            for child in current_node:iter_children() do
                if child:type() == "block_mapping" then
                    current_node = child
                    break
                end
            end
        end

        if index then
            -- Handle array access
            local array_index = tonumber(index)

            -- First find the mapping pair with the array key
            if key then
                for child in current_node:iter_children() do
                    if child:type() == "block_mapping_pair" or child:type() == "flow_mapping_pair" or child:type() == "pair" then
                        local key_node = child:field("key")[1]
                        if key_node then
                            local found_key = clean_key(vim.treesitter.get_node_text(key_node, 0))
                            if found_key == key then
                                -- Get the value node which should contain the array
                                local value_node = child:field("value")[1]
                                if value_node then
                                    -- If the value is a block_node, get its content
                                    if value_node:type() == "block_node" then
                                        for content in value_node:iter_children() do
                                            if content:type() == "block_sequence" or content:type() == "flow_sequence" then
                                                current_node = content
                                                break
                                            end
                                        end
                                    else
                                        current_node = value_node
                                    end
                                end
                            end
                        end
                    end
                end
            end

            -- Now find the array item at the specified index
            local current_index = 0
            for child in current_node:iter_children() do
                local type = child:type()
                if type == "block_sequence_item" or type == "flow_sequence_item" then
                    if current_index == array_index then
                        -- For list items, we need to get the actual content node
                        for content in child:iter_children() do
                            if content:type() == "block_node" or
                                content:type() == "block_mapping" or
                                content:type() == "flow_mapping" then
                                current_node = content
                                found = true
                                break
                            elseif content:type() == "flow_node" or content:type() == "plain_scalar" then
                                -- For scalar values, use the content node directly
                                current_node = content
                                found = true
                                break
                            end
                        end
                        if found then break end
                    end
                    current_index = current_index + 1
                end
            end
        else
            -- Handle object property access
            for child in current_node:iter_children() do
                local type = child:type()

                -- Handle both direct key-value pairs and nested mappings
                if type == "block_mapping_pair" or type == "flow_mapping_pair" or type == "pair" then
                    local key_node = child:field("key")[1]
                    if key_node then
                        local key = clean_key(vim.treesitter.get_node_text(key_node, 0))
                        if key == segment then
                            -- Get the value node
                            local value_node = child:field("value")[1]
                            if value_node then
                                -- For value nodes, we need to get the actual content if it's a block_node
                                if value_node:type() == "block_node" then
                                    for content in value_node:iter_children() do
                                        if content:type() == "block_mapping" or
                                            content:type() == "flow_mapping" then
                                            current_node = content
                                            found = true
                                            break
                                        elseif content:type() == "block_sequence" or content:type() == "flow_sequence" then
                                            -- If we found a sequence, get its first item
                                            current_node = content
                                            for item in content:iter_children() do
                                                if item:type() == "block_sequence_item" or item:type() == "flow_sequence_item" then
                                                    -- Get the content of the first item
                                                    for item_content in item:iter_children() do
                                                        if item_content:type() == "block_node" or
                                                            item_content:type() == "block_mapping" or
                                                            item_content:type() == "flow_mapping" then
                                                            current_node = item_content
                                                            found = true
                                                            break
                                                        elseif item_content:type() == "flow_node" or
                                                            item_content:type() == "plain_scalar" then
                                                            current_node = item_content
                                                            found = true
                                                            break
                                                        end
                                                    end
                                                    break
                                                end
                                            end
                                            if found then break end
                                        end
                                    end
                                else
                                    current_node = value_node
                                    found = true
                                end
                            else
                                current_node = child
                                found = true
                            end
                            if found then break end
                        end
                    end
                end
            end
        end

        if not found then
            return false
        end
    end

    -- Jump to the found node
    local start_row, start_col = current_node:start()
    vim.api.nvim_win_set_cursor(0, { start_row + 1, start_col })
    return true
end

---Open a popup window to input a path and jump to it
---@return boolean success Whether the jump was successful
function M.jumpwindow()
    local ft = vim.bo.filetype

    -- Get cursor position
    local cursor = vim.api.nvim_win_get_cursor(0)
    local row, col = cursor[1] - 1, cursor[2]

    -- Create a floating window
    local width = 35
    local height = 1 -- Reduced to just the input line
    local border = 1

    -- Calculate window position (to the far right of cursor)
    local win_width = vim.api.nvim_win_get_width(0)
    local win_height = vim.api.nvim_win_get_height(0)

    -- Position window to the far right of cursor
    local col_offset = col + 10            -- Fixed offset from cursor
    if col_offset + width > win_width then
        col_offset = win_width - width - 2 -- Keep within screen bounds
    end

    -- Create the floating window
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, {
        relative = "cursor", -- Position relative to cursor instead of window
        row = 0,             -- Same row as cursor
        col = 10,            -- Offset from cursor
        width = width,
        height = height,
        border = "rounded", -- More elegant border style
        style = "minimal",
        noautocmd = true,
        title = " Jump to Path • <Enter> to jump • <Esc> to cancel ", -- Combined title and key bindings
        title_pos = "center", -- Center the title
    })

    -- Set up the buffer
    vim.api.nvim_buf_set_option(buf, "buftype", "prompt")
    vim.api.nvim_buf_set_option(buf, "modifiable", true)
    vim.fn.prompt_setprompt(buf, "Path: ")

    -- Set up keymaps
    local function close_win()
        vim.api.nvim_win_close(win, true)
    end

    local function handle_enter()
        local path = vim.api.nvim_buf_get_lines(buf, 0, 1, true)[1]
        if path then
            path = path:gsub("^Path: ", "")
            close_win()
            if path ~= "" then
                return M.jump_to_path(ft, path)
            end
        end
        return false
    end

    -- Set up keymaps for both insert and normal mode
    vim.keymap.set({ "n", "i" }, "<CR>", handle_enter, { buffer = buf, nowait = true })
    vim.keymap.set({ "n", "i" }, "<Esc>", close_win, { buffer = buf, nowait = true })

    -- Start insert mode
    vim.cmd("startinsert")

    -- Return true to indicate the popup was created successfully
    return true
end

return M
