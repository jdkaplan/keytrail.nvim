local M = {}

-- Initialize the plugin
function M.init()
    local keytrail = require('keytrail')
    
    -- Set up autocommands for cursor movement
    vim.api.nvim_create_autocmd({"CursorMoved", "CursorMovedI"}, {
        group = vim.api.nvim_create_augroup("KeyTrailCursor", { clear = true }),
        callback = function()
            keytrail.handle_cursor_move()
        end
    })

    -- Set up autocommands for window changes
    vim.api.nvim_create_autocmd({"WinScrolled", "WinClosed"}, {
        group = vim.api.nvim_create_augroup("KeyTrailWindow", { clear = true }),
        callback = function()
            keytrail.handle_window_change()
        end
    })

    -- Set up autocommands for buffer changes
    vim.api.nvim_create_autocmd({"BufEnter", "BufLeave"}, {
        group = vim.api.nvim_create_augroup("KeyTrailBuffer", { clear = true }),
        callback = function()
            keytrail.handle_buffer_change()
        end
    })
end

-- Call init when the plugin is loaded
M.init()

return M 