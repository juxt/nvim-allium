local M = {}
local config = require("allium.config")

local function attach_keymaps(bufnr)
  local keymaps = config.options.keymaps
  if not keymaps.enabled then
    return
  end

  local function map(mode, lhs, rhs, desc)
    if lhs then
      vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = "Allium: " .. desc })
    end
  end

  map("n", keymaps.definition, vim.lsp.buf.definition, "Go to definition")
  map("n", keymaps.hover, vim.lsp.buf.hover, "Show hover documentation")
  map("n", keymaps.references, vim.lsp.buf.references, "Find references")
  map("n", keymaps.rename, vim.lsp.buf.rename, "Rename symbol")
  map("n", keymaps.code_action, vim.lsp.buf.code_action, "Show code actions")
  map("n", keymaps.format, function()
    vim.lsp.buf.format({ async = true })
  end, "Format buffer")
  map("n", keymaps.prev_diagnostic, vim.diagnostic.goto_prev, "Previous diagnostic")
  map("n", keymaps.next_diagnostic, vim.diagnostic.goto_next, "Next diagnostic")
  map("n", keymaps.loclist, vim.diagnostic.setloclist, "Open diagnostic loclist")
end

local function setup_lsp_native()
  local lsp_opts = config.options.lsp
  vim.lsp.config("allium", {
    cmd = lsp_opts.cmd,
    filetypes = lsp_opts.filetypes,
    root_markers = lsp_opts.root_markers,
    settings = lsp_opts.settings,
  })
  vim.lsp.enable("allium")

  local group = vim.api.nvim_create_augroup("allium_lsp_attach", { clear = true })
  vim.api.nvim_create_autocmd("LspAttach", {
    group = group,
    callback = function(args)
      local client = vim.lsp.get_client_by_id(args.data.client_id)
      if client and client.name == "allium" then
        attach_keymaps(args.buf)
      end
    end,
  })
end

local function setup_lsp_legacy()
  local lsp_opts = config.options.lsp
  local ok, lspconfig = pcall(require, "lspconfig")
  if not ok then
    return
  end
  local configs = require("lspconfig.configs")

  if not configs.allium then
    configs.allium = {
      default_config = {
        cmd = lsp_opts.cmd,
        filetypes = lsp_opts.filetypes,
        root_dir = lsp_opts.root_dir,
        settings = lsp_opts.settings,
      },
    }
  end

  lspconfig.allium.setup({
    on_attach = function(client, bufnr)
      attach_keymaps(bufnr)
      vim.bo[bufnr].omnifunc = "v:lua.vim.lsp.omnifunc"
      vim.bo[bufnr].formatexpr = "v:lua.vim.lsp.formatexpr()"
    end,
  })
end

function M.setup(opts)
  config.setup(opts)
  if vim.lsp.config then
    setup_lsp_native()
  else
    setup_lsp_legacy()
  end
  require("allium.treesitter").setup()
end

return M
