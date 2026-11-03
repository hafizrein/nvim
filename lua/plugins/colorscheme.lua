-- Everforest, applied once.
--
-- LazyVim's default colorscheme is `require("tokyonight").load()`, which runs
-- during LazyVim's own `config` (priority 10000) and is then immediately thrown
-- away when this plugin (priority 1000) applies everforest. Requiring tokyonight
-- pulls in its config/theme/colors/groups/hsluv modules and builds the whole
-- highlight set for nothing: ~8 ms of every startup.
--
-- So instead of configuring everforest here and letting LazyVim paint tokyonight
-- first, the colorscheme is handed to LazyVim (`opts.colorscheme`). LazyVim then
-- calls `:colorscheme everforest`, which makes lazy.nvim load this plugin on
-- demand (Loader.colorscheme) and then source `colors/everforest.vim` exactly
-- once. The `lazy = false` entry stays so the plugin is ordered early, but it has
-- no `config` any more -- a second `:colorscheme` call would re-run the whole
-- 1900-line highlight file for no reason.
--
-- Options must be set before the colors file is sourced, hence `init` (runs for
-- every plugin before any start plugin is loaded, so it also precedes LazyVim's
-- config).
--
-- Everforest defines no `@lsp.*` semantic-token groups, which is what we want:
-- pyright's semantic tokens then leave tree-sitter's capture untouched instead of
-- overriding it. (onedarkpro links `@lsp.type.parameter` -> `@parameter` and
-- `@lsp.type.namespace` -> `@namespace`, and neither of those groups exists, so
-- Python parameters/namespaces lost their colour entirely.)
return {
  {
    "sainnhe/everforest",
    lazy = false,
    priority = 1000,
    init = function()
      vim.g.everforest_background = "medium"
      vim.g.everforest_better_performance = 1
      -- Cursor colour. Everforest only paints a coloured cursor when this is set
      -- (colors/everforest.vim:92 uses `s:palette[s:configuration.cursor]`);
      -- unset it falls through to a plain reverse block, which is the white
      -- cursor you saw. "green" is the palette's #a7c080.
      vim.g.everforest_cursor = "green"
    end,
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "everforest",
    },
  },
}
