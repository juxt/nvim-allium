local M = {}

-- vim.health.ok/error/warn/start were added in 0.10; 0.9 uses report_* variants
local health_start = vim.health.start or vim.health.report_start
local health_ok = vim.health.ok or vim.health.report_ok
local health_warn = vim.health.warn or vim.health.report_warn
local health_error = vim.health.error or vim.health.report_error

local function get_options()
  local config = require("allium.config")
  if next(config.options) ~= nil then
    return config.options
  end
  return config.defaults
end

local function check_lsp()
  local opts = get_options()
  local lsp_cmd = opts.lsp.cmd[1]
  if vim.fn.executable(lsp_cmd) == 1 then
    health_ok(string.format("allium-lsp found at %s", vim.fn.exepath(lsp_cmd)))
  else
    health_error("allium-lsp binary not found", "Ensure allium-lsp is in your PATH or configure lsp.cmd in setup()")
  end
end

local function check_version()
  if vim.fn.has("nvim-0.9") == 1 then
    health_ok("Neovim version >= 0.9.0")
  else
    health_error("Neovim version < 0.9.0", "Upgrade to Neovim 0.9.0 or newer for full Allium support")
    return
  end

  if vim.lsp.config then
    health_ok("Neovim 0.11+ native LSP support detected")
  else
    health_ok("Using lspconfig for LSP support (Neovim < 0.11)")
  end
end

local function check_dependencies()
  if vim.lsp.config then
    if pcall(require, "lspconfig") then
      health_ok("nvim-lspconfig available (optional on 0.11+)")
    else
      health_ok("nvim-lspconfig not installed (not required on 0.11+)")
    end
  else
    if pcall(require, "lspconfig") then
      health_ok("nvim-lspconfig available")
    else
      health_error("nvim-lspconfig not found", "Install nvim-lspconfig for LSP support, or upgrade to Neovim 0.11+")
    end
  end

  if pcall(require, "nvim-treesitter") then
    health_ok("nvim-treesitter available")
    local ok, parsers = pcall(require, "nvim-treesitter.parsers")
    local has_parser = false
    if ok and type(parsers) == "table" then
      if type(parsers.has_parser) == "function" then
        has_parser = parsers.has_parser("allium")
      elseif type(parsers.get_parser_configs) == "function" then
        local parser_configs = parsers.get_parser_configs()
        has_parser = type(parser_configs) == "table" and parser_configs.allium ~= nil
      else
        has_parser = parsers.allium ~= nil
      end
    end

    if has_parser then
      health_ok("allium tree-sitter parser installed/configured")
    else
      health_warn("allium tree-sitter parser not installed", "Run :TSInstall allium")
    end
  else
    health_error("nvim-treesitter not found", "Install nvim-treesitter for syntax highlighting")
  end
end

function M.check()
  health_start("allium")
  check_version()
  check_lsp()
  check_dependencies()
end

return M
