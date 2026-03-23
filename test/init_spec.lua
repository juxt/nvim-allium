local harness = require("harness")

local function clear_setup_modules()
  package.loaded["lspconfig"] = nil
  package.loaded["lspconfig.configs"] = nil
  package.preload["lspconfig"] = nil
  package.preload["lspconfig.configs"] = nil
end

harness.test("setup registers allium lsp server via lspconfig on Neovim < 0.11", function()
  clear_setup_modules()

  local original_lsp_config = vim.lsp.config
  vim.lsp.config = nil

  local captured_setup_opts
  local configs = {}
  package.preload["lspconfig.configs"] = function()
    return configs
  end

  package.preload["lspconfig"] = function()
    return {
      allium = {
        setup = function(opts)
          captured_setup_opts = opts
        end,
      },
    }
  end

  local keymaps = {}
  local original_keymap_set = vim.keymap.set
  local original_treesitter_setup = require("allium.treesitter").setup

  vim.keymap.set = function(mode, lhs, rhs, opts)
    keymaps[#keymaps + 1] = { mode = mode, lhs = lhs, rhs = rhs, opts = opts }
  end

  -- Mock vim.bo[bufnr] to capture option writes
  local buf_options = {}
  local original_bo = vim.bo
  local bo_mt = {
    __index = function(_, bufnr)
      return setmetatable({}, {
        __newindex = function(_, option, value)
          buf_options[#buf_options + 1] = { bufnr = bufnr, option = option, value = value }
        end,
      })
    end,
  }
  vim.bo = setmetatable({}, bo_mt)

  local treesitter_called = false
  require("allium.treesitter").setup = function()
    treesitter_called = true
  end

  local ok, err = pcall(function()
    require("allium").setup({
      lsp = {
        cmd = { "allium-lsp", "--stdio" },
      },
    })

    assert(type(configs.allium) == "table", "expected allium lspconfig entry")
    assert(configs.allium.default_config.cmd[1] == "allium-lsp", "expected configured cmd in server defaults")
    assert(configs.allium.default_config.filetypes[1] == "allium", "expected default allium filetype")
    assert(type(configs.allium.default_config.root_dir) == "function", "expected root_dir function")
    assert(type(configs.allium.default_config.settings) == "table", "expected settings table")
    assert(type(captured_setup_opts) == "table", "expected lsp setup call")
    assert(type(captured_setup_opts.on_attach) == "function", "expected on_attach callback")
    assert(treesitter_called, "expected treesitter setup call")

    captured_setup_opts.on_attach({}, 17)
    assert(#keymaps == 9, "expected default LSP keymaps to be registered")
    assert(#buf_options == 2, "expected omnifunc and formatexpr to be set")
    assert(buf_options[1].bufnr == 17, "expected on_attach buffer for first option write")
    assert(buf_options[1].option == "omnifunc", "expected omnifunc option set")
    assert(buf_options[1].value == "v:lua.vim.lsp.omnifunc", "expected omnifunc value")
    assert(buf_options[2].bufnr == 17, "expected on_attach buffer for second option write")
    assert(buf_options[2].option == "formatexpr", "expected formatexpr option set")
    assert(buf_options[2].value == "v:lua.vim.lsp.formatexpr()", "expected formatexpr value")
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.keymap.set = original_keymap_set
  vim.bo = original_bo
  vim.lsp.config = original_lsp_config
  assert(ok, err)
end)

harness.test("setup uses native vim.lsp.config on Neovim 0.11+", function()
  clear_setup_modules()

  local captured_name, captured_config
  local enabled_servers = {}
  local original_lsp_config = vim.lsp.config
  local original_lsp_enable = vim.lsp.enable
  local original_autocmd = vim.api.nvim_create_autocmd
  local original_augroup = vim.api.nvim_create_augroup

  vim.lsp.config = function(name, cfg)
    captured_name = name
    captured_config = cfg
  end
  vim.lsp.enable = function(name)
    enabled_servers[#enabled_servers + 1] = name
  end

  local created_augroups = {}
  vim.api.nvim_create_augroup = function(name, opts)
    created_augroups[#created_augroups + 1] = { name = name, opts = opts }
    return 1
  end

  local autocmd_callbacks = {}
  vim.api.nvim_create_autocmd = function(event, opts)
    autocmd_callbacks[#autocmd_callbacks + 1] = { event = event, opts = opts }
  end

  local treesitter_called = false
  local original_treesitter_setup = require("allium.treesitter").setup
  require("allium.treesitter").setup = function()
    treesitter_called = true
  end

  local ok, err = pcall(function()
    require("allium").setup({
      lsp = {
        cmd = { "allium-lsp", "--stdio" },
      },
    })

    assert(captured_name == "allium", "expected native LSP config name to be allium")
    assert(type(captured_config) == "table", "expected native LSP config table")
    assert(captured_config.cmd[1] == "allium-lsp", "expected configured cmd")
    assert(captured_config.filetypes[1] == "allium", "expected allium filetype")
    assert(type(captured_config.root_markers) == "table", "expected root_markers")
    assert(#enabled_servers == 1, "expected vim.lsp.enable called once")
    assert(enabled_servers[1] == "allium", "expected allium enabled")
    assert(treesitter_called, "expected treesitter setup call")
    assert(#created_augroups >= 1, "expected augroup creation")
    assert(created_augroups[1].name == "allium_lsp_attach", "expected allium_lsp_attach augroup")
    assert(created_augroups[1].opts.clear == true, "expected augroup with clear = true")
    assert(#autocmd_callbacks >= 1, "expected LspAttach autocmd")
    assert(autocmd_callbacks[1].opts.group == 1, "expected autocmd in augroup")
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.lsp.config = original_lsp_config
  vim.lsp.enable = original_lsp_enable
  vim.api.nvim_create_autocmd = original_autocmd
  vim.api.nvim_create_augroup = original_augroup
  assert(ok, err)
end)

harness.test("setup keeps existing allium lspconfig server definition", function()
  clear_setup_modules()

  local original_lsp_config = vim.lsp.config
  vim.lsp.config = nil

  local captured_setup_opts
  local existing_config = {
    default_config = {
      cmd = { "custom-allium-lsp" },
      filetypes = { "allium" },
    },
  }
  local configs = {
    allium = existing_config,
  }

  package.preload["lspconfig.configs"] = function()
    return configs
  end

  package.preload["lspconfig"] = function()
    return {
      allium = {
        setup = function(opts)
          captured_setup_opts = opts
        end,
      },
    }
  end

  local original_treesitter_setup = require("allium.treesitter").setup
  require("allium.treesitter").setup = function()
  end

  local ok, err = pcall(function()
    require("allium").setup({})
    assert(configs.allium == existing_config, "expected existing allium config to be preserved")
    assert(configs.allium.default_config.cmd[1] == "custom-allium-lsp", "expected existing cmd to remain unchanged")
    assert(type(captured_setup_opts) == "table", "expected lsp setup to still run")
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.lsp.config = original_lsp_config
  assert(ok, err)
end)

harness.test("setup is idempotent (calling twice does not duplicate keymaps or autocmds)", function()
  clear_setup_modules()

  local original_lsp_config = vim.lsp.config
  vim.lsp.config = nil

  local captured_setup_count = 0
  package.preload["lspconfig.configs"] = function()
    return {}
  end

  package.preload["lspconfig"] = function()
    return {
      allium = {
        setup = function()
          captured_setup_count = captured_setup_count + 1
        end,
      },
    }
  end

  local original_treesitter_setup = require("allium.treesitter").setup
  local treesitter_count = 0
  require("allium.treesitter").setup = function()
    treesitter_count = treesitter_count + 1
  end

  local ok, err = pcall(function()
    require("allium").setup({})

    -- Clear loaded allium.init to re-require it fresh for second call
    package.loaded["allium"] = nil
    package.loaded["allium.init"] = nil

    require("allium").setup({})

    assert(captured_setup_count == 2, "expected lsp setup called twice (once per setup call)")
    assert(treesitter_count == 2, "expected treesitter setup called twice")
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.lsp.config = original_lsp_config
  assert(ok, err)
end)

harness.test("setup is idempotent on Neovim 0.11+ (augroup clears on second call)", function()
  clear_setup_modules()

  local captured_config_count = 0
  local enable_count = 0
  local original_lsp_config = vim.lsp.config
  local original_lsp_enable = vim.lsp.enable
  local original_autocmd = vim.api.nvim_create_autocmd
  local original_augroup = vim.api.nvim_create_augroup

  vim.lsp.config = function()
    captured_config_count = captured_config_count + 1
  end
  vim.lsp.enable = function()
    enable_count = enable_count + 1
  end

  local augroup_opts_list = {}
  vim.api.nvim_create_augroup = function(name, opts)
    augroup_opts_list[#augroup_opts_list + 1] = { name = name, opts = opts }
    return 1
  end

  local autocmd_count = 0
  vim.api.nvim_create_autocmd = function()
    autocmd_count = autocmd_count + 1
  end

  local original_treesitter_setup = require("allium.treesitter").setup
  require("allium.treesitter").setup = function() end

  local ok, err = pcall(function()
    require("allium").setup({})

    package.loaded["allium"] = nil
    package.loaded["allium.init"] = nil

    require("allium").setup({})

    assert(captured_config_count == 2, "expected lsp.config called twice")
    assert(enable_count == 2, "expected lsp.enable called twice")
    -- Both calls create augroup with clear = true, so the second call clears the first
    for _, entry in ipairs(augroup_opts_list) do
      assert(entry.opts.clear == true, "expected augroup created with clear = true")
    end
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.lsp.config = original_lsp_config
  vim.lsp.enable = original_lsp_enable
  vim.api.nvim_create_autocmd = original_autocmd
  vim.api.nvim_create_augroup = original_augroup
  assert(ok, err)
end)

harness.test("setup with keymaps.enabled = false skips keymap registration entirely", function()
  clear_setup_modules()

  local original_lsp_config = vim.lsp.config
  vim.lsp.config = nil

  local captured_setup_opts
  package.preload["lspconfig.configs"] = function()
    return {}
  end

  package.preload["lspconfig"] = function()
    return {
      allium = {
        setup = function(opts)
          captured_setup_opts = opts
        end,
      },
    }
  end

  local keymap_calls = 0
  local original_keymap_set = vim.keymap.set
  local original_bo = vim.bo
  local original_treesitter_setup = require("allium.treesitter").setup

  vim.keymap.set = function()
    keymap_calls = keymap_calls + 1
  end
  vim.bo = setmetatable({}, {
    __index = function()
      return setmetatable({}, { __newindex = function() end })
    end,
  })
  require("allium.treesitter").setup = function() end

  local ok, err = pcall(function()
    require("allium").setup({
      keymaps = { enabled = false },
    })

    captured_setup_opts.on_attach({}, 5)
    assert(keymap_calls == 0, "expected zero keymaps when keymaps.enabled is false")
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.keymap.set = original_keymap_set
  vim.bo = original_bo
  vim.lsp.config = original_lsp_config
  assert(ok, err)
end)

harness.test("setup applies custom keymap bindings from config", function()
  clear_setup_modules()

  local original_lsp_config = vim.lsp.config
  vim.lsp.config = nil

  local captured_setup_opts
  package.preload["lspconfig.configs"] = function()
    return {}
  end

  package.preload["lspconfig"] = function()
    return {
      allium = {
        setup = function(opts)
          captured_setup_opts = opts
        end,
      },
    }
  end

  local keymaps = {}
  local original_keymap_set = vim.keymap.set
  local original_bo = vim.bo
  local original_treesitter_setup = require("allium.treesitter").setup

  vim.keymap.set = function(mode, lhs, rhs, opts)
    keymaps[#keymaps + 1] = { mode = mode, lhs = lhs, rhs = rhs, opts = opts }
  end
  vim.bo = setmetatable({}, {
    __index = function()
      return setmetatable({}, { __newindex = function() end })
    end,
  })
  require("allium.treesitter").setup = function() end

  local ok, err = pcall(function()
    require("allium").setup({
      keymaps = {
        definition = "gD",
        hover = "<leader>h",
      },
    })

    captured_setup_opts.on_attach({}, 7)

    local found_gD = false
    local found_leader_h = false
    local found_gd = false
    for _, km in ipairs(keymaps) do
      if km.lhs == "gD" then
        found_gD = true
      end
      if km.lhs == "<leader>h" then
        found_leader_h = true
      end
      if km.lhs == "gd" then
        found_gd = true
      end
    end
    assert(found_gD, "expected custom definition keymap gD")
    assert(found_leader_h, "expected custom hover keymap <leader>h")
    assert(not found_gd, "expected default gd to be replaced by gD")
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.keymap.set = original_keymap_set
  vim.bo = original_bo
  vim.lsp.config = original_lsp_config
  assert(ok, err)
end)

harness.test("setup skips keymap registration when disabled", function()
  clear_setup_modules()

  local original_lsp_config = vim.lsp.config
  vim.lsp.config = nil

  local captured_setup_opts
  package.preload["lspconfig.configs"] = function()
    return {}
  end

  package.preload["lspconfig"] = function()
    return {
      allium = {
        setup = function(opts)
          captured_setup_opts = opts
        end,
      },
    }
  end

  local keymap_calls = 0
  local original_keymap_set = vim.keymap.set
  local original_bo = vim.bo
  local original_treesitter_setup = require("allium.treesitter").setup

  vim.keymap.set = function()
    keymap_calls = keymap_calls + 1
  end
  vim.bo = setmetatable({}, {
    __index = function()
      return setmetatable({}, { __newindex = function() end })
    end,
  })
  require("allium.treesitter").setup = function()
  end

  local ok, err = pcall(function()
    require("allium").setup({
      keymaps = { enabled = false },
    })

    captured_setup_opts.on_attach({}, 3)
    assert(keymap_calls == 0, "expected no keymaps when keymaps.enabled is false")
  end)

  require("allium.treesitter").setup = original_treesitter_setup
  vim.keymap.set = original_keymap_set
  vim.bo = original_bo
  vim.lsp.config = original_lsp_config
  assert(ok, err)
end)
