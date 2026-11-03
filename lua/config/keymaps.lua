-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
-- Open the LazyVim home dashboard
vim.keymap.set("n", "<leader>h", Snacks.dashboard.open, { desc = "Open Dashboard" })

-- Terminal in a vertical split on the right (same key toggles it).
--
-- Two details make the toggle behave:
--  * `count = 2` gives this terminal its own Snacks instance. Terminals are
--    cached by cmd/cwd/env/count, so without it `<leader>fv` would grab the
--    bottom terminal from `<leader>ft` and ignore the `position` below.
--  * `cwd` must be stable, otherwise the cache key changes and every press
--    opens a new terminal instead of toggling. `LazyVim.root()` resolves from
--    the *current* buffer, so it changes when focus sits in the terminal; in
--    that case resolve it from a regular window instead.
local function root_for_terminal()
  local cur = vim.api.nvim_get_current_buf()
  if vim.bo[cur].filetype ~= "snacks_terminal" then
    return LazyVim.root()
  end
  for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local buf = vim.api.nvim_win_get_buf(win)
    if buf ~= cur and vim.bo[buf].buftype == "" and vim.bo[buf].filetype ~= "snacks_terminal" then
      return LazyVim.root({ buf = buf })
    end
  end
  return LazyVim.root({ buf = cur })
end

vim.keymap.set("n", "<leader>fv", function()
  Snacks.terminal(nil, {
    cwd = root_for_terminal(),
    count = 2,
    win = { position = "right", width = 0.4 },
  })
end, { desc = "Terminal (Vertical Split)" })

-- Toggle Oh My Pi. Mapped in both modes so `gv`/visual selections reach the
-- agent: a selection is published as `file:12-40` (or `file:12-12` for a single
-- line) and omp.nvim keeps re-publishing that range after you leave visual mode
-- for as long as the cursor stays inside it — including across the CursorHold
-- that fires `updatetime` after Esc. Moving outside the range, or to another
-- file, ends it. So: select, hit the keybind, type.
vim.keymap.set({ "n", "v" }, "<leader>ao", function()
  Snacks.terminal.toggle("omp", {
    win = {
      position = "right",
      width = 0.4,
    },
  })
end, { desc = "Toggle Oh My Pi" })

vim.keymap.set("t", "jk", [[<C-\><C-n>]], { desc = "Exit terminal mode" })
