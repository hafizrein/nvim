local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },

    -- import/override with your plugins
    { import = "plugins" },
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  install = { colorscheme = { "tokyonight", "habamax" } },
  -- The update checker walks every installed plugin at ~VeryLazy and compares the
  -- checked-out commit against its target with `Git.get_target`. That resolves a
  -- version constraint by reading every *local* tag of a repo: 55-350 tags for
  -- blink.cmp / lazy.nvim / LazyVim, ~320 ms total across 48 plugins with the ref
  -- reads themselves costing only 9 ms. It runs on the main thread, so it blocks
  -- the editor exactly when LSP clients are starting: measured on this machine,
  -- opening a Python file attached pyright at ~886 ms with the checker off vs
  -- ~1200 ms with it on.
  --
  -- It is off by default in lazy.nvim, and the notification is already disabled
  -- below, so the only thing it fed was the update counter in lualine -- the count
  -- also goes away from lazy's own state after this. `:Lazy update` still works,
  -- and `:Lazy` shows pending updates once checked.
  checker = {
    enabled = false, -- don't block startup on the update check
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- matchit stays: `%` jumping between if/end is worth its cost.
        -- "matchit",
        -- matchparen: MEASURED on a 2505-line C# file,
        -- 100 CursorMoved = 63.1 ms with it, 21.0 ms without — 3x the cost of
        -- every cursor move, for a bracket highlight treesitter already draws.
        -- This is the single biggest stutter source in this config.
        "matchparen",
        -- netrw's directory browser. Unused here: the snacks explorer replaces it
        -- (`explorer.replace_netrw` deletes the FileExplorer augroup and handles
        -- directories on BufEnter), verified by opening a directory -- the buffer
        -- comes up as filetype=snacks_picker_list. Saves netrwPlugin.vim +
        -- netrw/plugin/netrwPlugin.vim on every start.
        "netrwPlugin",
        -- Remote plugin host. No plugin in this config ships an rplugin manifest
        -- (nothing under nvim-data/lazy/*/rplugin, no nvim-data/rplugin.vim), and
        -- the Python provider is already off in config/options.lua, so the manifest
        -- scan on every start finds nothing.
        "rplugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
