-- Oh My Pi integration (cursor + selection tracking for the agent pane).
--
-- POINTED AT A FORK, DELIBERATELY. Upstream `rauls-kjarners/omp.nvim` only
-- speaks AF_UNIX, and Neovim's uv_pipe_t on Windows cannot bind or connect an
-- AF_UNIX path at all (both fail with EACCES), so upstream is silently broken
-- here. The `patched` branch adds a Win32 named-pipe transport plus the sticky
-- selection / single-line-range fixes.
--
-- Switching this back to the upstream repo would silently disable cursor
-- tracking on Windows — `:Lazy update` would overwrite the working tree and the
-- widget would stop appearing, with no error. If upstream ever merges equivalent
-- support, point the repo back and delete `branch`.
--
-- The OMP-side half (the extension under ~/.omp/plugins/node_modules/omp.nvim)
-- is separate and is already patched on disk; `omp plugin install` would
-- overwrite it, so re-apply from the same branch if that is ever re-run.
return {
  {
    "hafizrein/omp.nvim",
    branch = "patched",
    event = "VeryLazy",
    config = function()
      require("omp").setup()
    end,
  },
}
