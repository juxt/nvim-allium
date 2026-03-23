local harness = require("harness")

harness.test("plugin loader sets global loaded guard", function()
  local root = vim.fn.getcwd()
  local plugin_file = root .. "/plugin/allium.lua"
  local original = vim.g.loaded_allium
  vim.g.loaded_allium = nil

  local ok, err = pcall(function()
    dofile(plugin_file)
    assert(vim.g.loaded_allium == 1, "expected plugin loader to set vim.g.loaded_allium")
  end)

  vim.g.loaded_allium = original
  assert(ok, err)
end)

harness.test("plugin loader is idempotent when guard is set", function()
  local root = vim.fn.getcwd()
  local plugin_file = root .. "/plugin/allium.lua"
  local original = vim.g.loaded_allium
  vim.g.loaded_allium = 1

  local ok, err = pcall(function()
    dofile(plugin_file)
    assert(vim.g.loaded_allium == 1, "expected plugin loader guard to remain set")
  end)

  vim.g.loaded_allium = original
  assert(ok, err)
end)

harness.test("ftdetect registers allium filetype for .allium extension", function()
  local root = vim.fn.getcwd()
  local ftdetect_file = root .. "/ftdetect/allium.lua"

  local ok, err = pcall(function()
    dofile(ftdetect_file)

    -- After running ftdetect/allium.lua, vim.filetype should recognise .allium
    local ft = vim.filetype.match({ filename = "test.allium" })
    assert(ft == "allium", "expected .allium extension to map to allium filetype, got " .. tostring(ft))
  end)

  assert(ok, err)
end)

harness.test("allium augroup is created by setup on native LSP path", function()
  local original_lsp_config = vim.lsp.config
  local original_lsp_enable = vim.lsp.enable
  local original_autocmd = vim.api.nvim_create_autocmd
  local original_augroup = vim.api.nvim_create_augroup

  -- Clear allium modules for fresh require
  for module_name, _ in pairs(package.loaded) do
    if module_name:match("^allium") then
      package.loaded[module_name] = nil
    end
  end

  local created_augroups = {}
  vim.lsp.config = function() end
  vim.lsp.enable = function() end
  vim.api.nvim_create_augroup = function(name, opts)
    created_augroups[#created_augroups + 1] = { name = name, opts = opts }
    return 1
  end
  vim.api.nvim_create_autocmd = function() end

  local original_treesitter_setup = require("allium.treesitter").setup
  require("allium.treesitter").setup = function() end

  local ok, err = pcall(function()
    require("allium").setup({})

    local found = false
    for _, ag in ipairs(created_augroups) do
      if ag.name == "allium_lsp_attach" then
        found = true
      end
    end
    assert(found, "expected allium_lsp_attach augroup to be created")
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.lsp.config = original_lsp_config
  vim.lsp.enable = original_lsp_enable
  vim.api.nvim_create_autocmd = original_autocmd
  vim.api.nvim_create_augroup = original_augroup
  assert(ok, err)
end)

harness.test("LspAttach autocmd is registered for allium client", function()
  local original_lsp_config = vim.lsp.config
  local original_lsp_enable = vim.lsp.enable
  local original_autocmd = vim.api.nvim_create_autocmd
  local original_augroup = vim.api.nvim_create_augroup

  for module_name, _ in pairs(package.loaded) do
    if module_name:match("^allium") then
      package.loaded[module_name] = nil
    end
  end

  local autocmd_events = {}
  vim.lsp.config = function() end
  vim.lsp.enable = function() end
  vim.api.nvim_create_augroup = function()
    return 1
  end
  vim.api.nvim_create_autocmd = function(event, opts)
    autocmd_events[#autocmd_events + 1] = { event = event, opts = opts }
  end

  local original_treesitter_setup = require("allium.treesitter").setup
  require("allium.treesitter").setup = function() end

  local ok, err = pcall(function()
    require("allium").setup({})

    local found_lsp_attach = false
    for _, entry in ipairs(autocmd_events) do
      if entry.event == "LspAttach" then
        found_lsp_attach = true
        assert(type(entry.opts.callback) == "function", "expected LspAttach autocmd to have a callback")
        assert(entry.opts.group == 1, "expected LspAttach autocmd to belong to the allium augroup")
      end
    end
    assert(found_lsp_attach, "expected LspAttach autocmd to be registered")
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.lsp.config = original_lsp_config
  vim.lsp.enable = original_lsp_enable
  vim.api.nvim_create_autocmd = original_autocmd
  vim.api.nvim_create_augroup = original_augroup
  assert(ok, err)
end)
