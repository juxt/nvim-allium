local M = {}

---@class AlliumConfig
M.defaults = {
  lsp = {
    cmd = { "allium-lsp", "--stdio" },
    filetypes = { "allium" },
    root_markers = { "allium.config.json", ".git" },
    root_dir = function(fname)
      local ok, util = pcall(require, "lspconfig.util")
      if ok then
        return util.root_pattern("allium.config.json", ".git")(fname)
      end
      return vim.fn.getcwd()
    end,
    settings = {},
  },
  treesitter = {
    ensure_installed = { "allium" },
  },
  keymaps = {
    enabled = true,
    definition = "gd",
    hover = "K",
    references = "gr",
    rename = "<leader>rn",
    code_action = "<leader>ca",
    format = "<leader>f",
    prev_diagnostic = "[d",
    next_diagnostic = "]d",
    loclist = "<leader>q",
  },
}

M.options = {}

function M.setup(opts)
  M.options = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

return M
