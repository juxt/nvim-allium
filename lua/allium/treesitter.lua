local M = {}

function M.setup()
  local ok, parsers = pcall(require, "nvim-treesitter.parsers")
  if not ok then
    return
  end

  local configs
  if type(parsers.get_parser_configs) == "function" then
    configs = parsers.get_parser_configs()
  elseif type(parsers) == "table" then
    configs = parsers
  end

  if type(configs) ~= "table" then
    return
  end

  if not configs.allium then
    configs.allium = {
      install_info = {
        url = "https://github.com/juxt/allium-tools",
        files = { "src/parser.c" },
        location = "packages/tree-sitter-allium",
        branch = "main",
      },
      filetype = "allium",
    }
  end
end

return M
