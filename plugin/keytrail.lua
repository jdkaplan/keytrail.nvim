local M = {}

-- Initialize the plugin
function M.init()
    require('keytrail').setup()
end

-- Call init when the plugin is loaded
M.init()

return M 