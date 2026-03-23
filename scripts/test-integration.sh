#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$ROOT_DIR/.nvim-test"
XDG_CONFIG_HOME="$TEST_ROOT/xdg/config"
XDG_DATA_HOME="$TEST_ROOT/xdg/data"
XDG_STATE_HOME="$TEST_ROOT/xdg/state"
XDG_CACHE_HOME="$TEST_ROOT/xdg/cache"
LSPCONFIG_DIR="$XDG_DATA_HOME/nvim/site/pack/test/start/nvim-lspconfig"
TREESITTER_DIR="$XDG_DATA_HOME/nvim/site/pack/test/start/nvim-treesitter"

if ! command -v nvim >/dev/null 2>&1; then
  echo "Neovim is required to run nvim-allium integration tests." >&2
  exit 1
fi

if ! command -v allium-lsp >/dev/null 2>&1; then
  echo "allium-lsp must be in your PATH for integration tests." >&2
  echo "Install it from https://github.com/juxt/allium-tools/releases" >&2
  exit 1
fi

if [[ ! -d "$LSPCONFIG_DIR" || ! -d "$TREESITTER_DIR" ]]; then
  echo "Neovim test dependencies are not installed." >&2
  echo "Run: ./scripts/test-install.sh" >&2
  exit 1
fi

cd "$ROOT_DIR"

mkdir -p "$XDG_CONFIG_HOME" "$XDG_STATE_HOME" "$XDG_CACHE_HOME"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
export ALLIUM_NVIM_TEST_ROOT="$ROOT_DIR"

nvim --headless -n -u NONE -i NONE \
  -c "lua local ok = pcall(dofile, 'test/integration_spec.lua'); if not ok then vim.cmd('cq 1'); else vim.cmd('qa!'); end"
