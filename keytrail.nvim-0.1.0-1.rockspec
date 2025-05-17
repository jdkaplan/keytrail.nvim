package = "keytrail.nvim"
version = "0.1.0-1"
source = {
   url = "git+https://github.com/your-username/keytrail.nvim.git",
   tag = "v0.1.0"
}
description = {
   summary = "A Neovim plugin that shows the current path in YAML and JSON files",
   detailed = [[
      A Neovim plugin that shows the current path in YAML and JSON files using TreeSitter.
      The path is displayed in a beautiful popup window with colored segments.
   ]],
   homepage = "https://github.com/your-username/keytrail.nvim",
   license = "MIT"
}
dependencies = {
   "lua >= 5.1",
   "nvim-treesitter"
}
build = {
   type = "builtin",
   modules = {
      ["keytrail"] = "lua/keytrail/init.lua",
   },
   install = {
      lua = {
         ["keytrail"] = "lua/keytrail",
      },
   },
} 