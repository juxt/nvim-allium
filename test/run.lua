local root = vim.fn.getcwd()
vim.opt.runtimepath:prepend(root)
package.path = table.concat({
  root .. "/test/?.lua",
  package.path,
}, ";")

local harness = require("harness")

require("config_spec")
require("treesitter_spec")
require("init_spec")
require("health_spec")
require("plugin_spec")

harness.run()
