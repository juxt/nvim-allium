#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$ROOT_DIR/.nvim-test"
XDG_DATA_HOME="$TEST_ROOT/xdg/data"
LSPCONFIG_DIR="$XDG_DATA_HOME/nvim/site/pack/test/start/nvim-lspconfig"
TREESITTER_DIR="$XDG_DATA_HOME/nvim/site/pack/test/start/nvim-treesitter"

mkdir -p "$XDG_DATA_HOME/nvim/site/pack/test/start"

if [[ ! -d "$LSPCONFIG_DIR" ]]; then
  git clone --depth 1 https://github.com/neovim/nvim-lspconfig "$LSPCONFIG_DIR"
fi

if [[ ! -d "$TREESITTER_DIR" ]]; then
  git clone --depth 1 https://github.com/nvim-treesitter/nvim-treesitter "$TREESITTER_DIR"
fi

echo "Installed Neovim test dependencies under $TEST_ROOT"
