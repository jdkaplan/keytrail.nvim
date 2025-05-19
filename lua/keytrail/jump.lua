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
            local current_index = 0
            for child in current_node:iter_children() do
                local type = child:type()
                if type == "block_sequence_item" or type == "flow_sequence_item" or type == "array" then
                    if current_index == array_index then
                        current_node = child
                        found = true
                        break
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
                                current_node = value_node
                            else
                                current_node = child
                            end
                            found = true
                            break
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

return M

