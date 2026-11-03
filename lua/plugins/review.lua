-- GitHub PR review (diffview + telescope underneath).
--
-- Both review.nvim and its dependencies used to load on every start: review.nvim
-- had no `lazy`/`cmd`/`keys`/`event`, so lazy treated it as a startup plugin, and
-- loading a plugin always loads its `dependencies` too (lazy ignores the dep's own
-- `lazy = true`). That pulled diffview.nvim (`plugin/diffview.lua` builds
-- `diffview.bootstrap`, ~5 ms) and telescope.nvim (~2 ms) into every session,
-- together ~13 ms, even though neither is reachable before you ask for a review.
--
-- `cmd` + `keys` below keep everything working and defer the whole cluster until
-- it is actually used: `:Review`, or one of the three global review keymaps that
-- review.nvim registers in its setup (home/help/jump -- see review/config.lua
-- keymaps.global). lazy installs a stub that loads the plugin and then replays the
-- key, so `,rh` reaches review.home.open() exactly as before. The deps still load
-- with it, which is what keeps `:Review comments` (telescope) and the diffview
-- integration working.
return {
  {
    "sindrets/diffview.nvim",
    lazy = true,
    cmd = { "DiffviewOpen", "DiffviewFileHistory" },
  },
  -- telescope reaches this config only through review.nvim (LazyVim's picker here is
  -- snacks: no other extra or plugin declares it), but `defaults.lazy = false` in
  -- config/lazy.lua makes any plugin without cmd/keys/event/ft load at startup. Left
  -- alone it would just move its ~2 ms from review.nvim's dependency load to its own.
  {
    "nvim-telescope/telescope.nvim",
    lazy = true,
    cmd = "Telescope",
  },
  {
    "sent-hil/review.nvim",
    dependencies = { "sindrets/diffview.nvim", "nvim-telescope/telescope.nvim" },
    cmd = "Review",
    keys = {
      { "<leader>rh", desc = "review: home screen (PR queue)" },
      { "<leader>r?", desc = "review: keymap cheatsheet" },
      { "<leader>rj", desc = "review: jump to review session tab" },
    },
    opts = {},
  },
}
