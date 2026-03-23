local harness = require("harness")

harness.test("config.setup merges defaults with overrides", function()
  local config = require("allium.config")
  config.setup({
    lsp = {
      cmd = { "node", "dist/bin.js", "--stdio" },
    },
    keymaps = {
      enabled = false,
    },
  })

  assert(config.options.lsp.cmd[1] == "node", "expected custom lsp command")
  assert(config.options.lsp.filetypes[1] == "allium", "expected default filetype to remain")
  assert(config.options.keymaps.enabled == false, "expected keymaps override")
  assert(config.options.keymaps.hover == "K", "expected default hover keymap to remain")
end)

harness.test("config.defaults includes root_markers for native LSP", function()
  local config = require("allium.config")
  config.setup({})

  assert(type(config.options.lsp.root_markers) == "table", "expected root_markers table")
  assert(config.options.lsp.root_markers[1] == "allium.config.json", "expected allium.config.json as first root marker")
end)

harness.test("config.setup deep merges nested lsp.settings", function()
  local config = require("allium.config")
  config.setup({
    lsp = {
      settings = {
        allium = { diagnostics = true },
      },
    },
  })

  assert(type(config.options.lsp.settings.allium) == "table", "expected nested lsp.settings.allium")
  assert(config.options.lsp.settings.allium.diagnostics == true, "expected diagnostics setting preserved")
  assert(config.options.lsp.cmd[1] == "allium-lsp", "expected default cmd to remain after settings merge")
  assert(config.options.lsp.filetypes[1] == "allium", "expected default filetypes to remain after settings merge")
end)

harness.test("config.setup deep merges keymaps subkeys", function()
  local config = require("allium.config")
  config.setup({
    keymaps = {
      definition = "gD",
    },
  })

  assert(config.options.keymaps.definition == "gD", "expected custom definition keymap")
  assert(config.options.keymaps.hover == "K", "expected default hover keymap preserved")
  assert(config.options.keymaps.enabled == true, "expected default keymaps.enabled preserved")
  assert(config.options.keymaps.references == "gr", "expected default references keymap preserved")
end)

harness.test("config.setup allows custom lsp.cmd to override default", function()
  local config = require("allium.config")
  config.setup({
    lsp = {
      cmd = { "node", "dist/server.js", "--stdio" },
    },
  })

  assert(config.options.lsp.cmd[1] == "node", "expected custom cmd first element")
  assert(config.options.lsp.cmd[2] == "dist/server.js", "expected custom cmd second element")
  assert(config.options.lsp.cmd[3] == "--stdio", "expected custom cmd third element")
  assert(#config.options.lsp.cmd == 3, "expected exactly three cmd elements")
end)

harness.test("config.setup with keymaps.enabled = false disables keymaps", function()
  local config = require("allium.config")
  config.setup({
    keymaps = { enabled = false },
  })

  assert(config.options.keymaps.enabled == false, "expected keymaps disabled")
  assert(config.options.keymaps.definition == "gd", "expected default definition keymap still present in config")
end)

harness.test("config.setup preserves unknown keys for forward compatibility", function()
  local config = require("allium.config")
  config.setup({
    experimental = { new_feature = true },
    lsp = {
      custom_option = "value",
    },
  })

  assert(config.options.experimental ~= nil, "expected unknown top-level key preserved")
  assert(config.options.experimental.new_feature == true, "expected nested unknown key preserved")
  assert(config.options.lsp.custom_option == "value", "expected unknown lsp key preserved")
  assert(config.options.lsp.cmd[1] == "allium-lsp", "expected defaults still present alongside unknown keys")
end)

harness.test("default config has expected lsp.cmd value", function()
  local config = require("allium.config")
  config.setup({})

  assert(type(config.options.lsp.cmd) == "table", "expected lsp.cmd to be a table")
  assert(config.options.lsp.cmd[1] == "allium-lsp", "expected default cmd to be allium-lsp")
  assert(config.options.lsp.cmd[2] == "--stdio", "expected default cmd arg to be --stdio")
  assert(#config.options.lsp.cmd == 2, "expected exactly two elements in default lsp.cmd")
end)

harness.test("default config has keymaps.enabled = true", function()
  local config = require("allium.config")
  config.setup({})

  assert(config.options.keymaps.enabled == true, "expected keymaps.enabled to default to true")
end)

harness.test("merging empty table preserves all defaults", function()
  local config = require("allium.config")
  config.setup({})

  assert(config.options.lsp.cmd[1] == "allium-lsp", "expected default lsp.cmd preserved")
  assert(config.options.lsp.filetypes[1] == "allium", "expected default filetype preserved")
  assert(config.options.lsp.root_markers[1] == "allium.config.json", "expected default root_markers preserved")
  assert(type(config.options.lsp.root_dir) == "function", "expected default root_dir function preserved")
  assert(type(config.options.lsp.settings) == "table", "expected default settings table preserved")
  assert(config.options.keymaps.enabled == true, "expected default keymaps.enabled preserved")
  assert(config.options.keymaps.definition == "gd", "expected default definition keymap preserved")
  assert(config.options.treesitter.ensure_installed[1] == "allium", "expected default treesitter config preserved")
end)

harness.test("all 9 default keymap values are present", function()
  local config = require("allium.config")
  config.setup({})

  local km = config.options.keymaps
  assert(km.definition == "gd", "expected default definition keymap")
  assert(km.hover == "K", "expected default hover keymap")
  assert(km.references == "gr", "expected default references keymap")
  assert(km.rename == "<leader>rn", "expected default rename keymap")
  assert(km.code_action == "<leader>ca", "expected default code_action keymap")
  assert(km.format == "<leader>f", "expected default format keymap")
  assert(km.prev_diagnostic == "[d", "expected default prev_diagnostic keymap")
  assert(km.next_diagnostic == "]d", "expected default next_diagnostic keymap")
  assert(km.loclist == "<leader>q", "expected default loclist keymap")
end)
