# nvim-allium

Neovim plugin for the [Allium](https://github.com/juxt/allium-tools) language. Provides LSP client configuration, tree-sitter syntax highlighting, diagnostics and standard LSP keymaps.

Requires `allium-lsp` to be installed and in your `$PATH`. Install it from [allium-tools releases](https://github.com/juxt/allium-tools/releases) or build from source.

## Install

### Neovim 0.11+ (native LSP)

No plugin manager needed for LSP and filetype support. The plugin adds tree-sitter highlighting, default keymaps and health checks on top.

```lua
-- lazy.nvim
{
  "juxt/nvim-allium",
  ft = { "allium" },
  opts = {},
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
  },
}
```

On 0.11+, `nvim-lspconfig` is not required. The plugin uses `vim.lsp.config()` and `vim.lsp.enable()` directly.

### Neovim 0.9+ (lspconfig)

```lua
-- lazy.nvim
{
  "juxt/nvim-allium",
  ft = { "allium" },
  opts = {},
  dependencies = {
    "neovim/nvim-lspconfig",
    "nvim-treesitter/nvim-treesitter",
  },
}
```

### Tree-sitter parser

After installing the plugin, run `:TSInstall allium` to compile the parser. Enable highlighting in your nvim-treesitter config:

```lua
require("nvim-treesitter.configs").setup({
  highlight = { enable = true },
})
```

## Configuration

All options are optional. Pass them to `setup()` or use lazy.nvim's `opts`:

```lua
require("allium").setup({
  lsp = {
    cmd = { "allium-lsp", "--stdio" },  -- LSP server command
    filetypes = { "allium" },
    root_markers = { "allium.config.json", ".git" },  -- 0.11+ native LSP
    settings = {},
  },
  keymaps = {
    enabled = true,       -- set false to handle your own mappings
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
})
```

## Health check

```vim
:checkhealth allium
```

Verifies Neovim version, `allium-lsp` binary, dependencies and tree-sitter parser status.

## Development

Run unit tests (headless Neovim, no external dependencies):

```bash
./scripts/test.sh
```

Run integration tests (requires `allium-lsp` in PATH and test dependencies installed):

```bash
./scripts/test-install.sh
./scripts/test-integration.sh
```

## Compatibility

Allium Tools core 3.x

## Licence

MIT
