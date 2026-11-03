-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Don't let headless/scripted runs overwrite saved sessions.
--
-- persistence.nvim saves on every VimLeavePre (`mks!` into
-- stdpath("state")/sessions/<cwd with \ and / replaced by %>.vim, gated only by
-- `need = 1`, i.e. at least one named buffer). Any non-interactive run that has a
-- buffer open and quits therefore rewrites the session of whatever directory it
-- ran in -- including runs that were never meant to touch real state, e.g. a
-- benchmark or smoke test opening a file from a project directory. That silently
-- replaced the session of every project touched that way with a single-file stub.
--
-- Headless runs are never an interactive session you'd want restored, so stop
-- persistence for them. vim.g.persistence_skip_save makes this explicit for
-- scripted interactive runs too.
if vim.fn.has("gui_running") == 0 and #vim.api.nvim_list_uis() == 0 then
  vim.api.nvim_create_autocmd("User", {
    pattern = "PersistenceSavePre",
    callback = function()
      require("persistence").stop()
    end,
  })
end

-- Dashboard -> "Projects" (p) -> <CR>: make session restore actually stick.
--
-- snacks' default `load_session` (snacks/picker/actions.lua) chdir's into the
-- project, runs the session section's action, and 100 ms later opens
-- Snacks.picker.files() *unless* a SessionLoadPost autocmd fired in the
-- meantime. Session loading is synchronous on the main thread, so that fixed
-- 100 ms window is the only thing separating "restored" from "not restored":
-- a session whose first `edit` target no longer exists aborts `:source` before
-- the event fires, and a large session can simply take longer than 100 ms. In
-- both cases the restored project is thrown away and a bare file picker is
-- shown instead -- the "doesn't open the project" symptom. Verified here:
-- <CR> on a project whose session points at a deleted file produced a `files`
-- picker even though the session's earlier buffers were already open.
--
-- Keep snacks' semantics, but also treat "the buffer list changed" as success
-- and give the load more time (250 ms). Only a genuinely empty restore (missing
-- or fully stale session) still falls through to the file picker.
--
-- LazyVim loads this file from inside its own `VeryLazy` callback, so a
-- `VeryLazy` hook registered here would miss the event; install directly, and
-- keep the hook only for the `nvim <file>` path where snacks loads later.
local function install_session_loader()
  local ok, Snacks = pcall(require, "snacks")
  if not ok or type(Snacks) ~= "table" or type(Snacks.config) ~= "table" then
    return false
  end
  Snacks.config.picker = Snacks.config.picker or {}
  Snacks.config.picker.actions = Snacks.config.picker.actions or {}
  Snacks.config.picker.actions.load_session = function(picker, item)
    picker:close()
    if not item then
      return
    end
    local function names()
      local t = {}
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        local n = vim.api.nvim_buf_get_name(b)
        if n ~= "" then
          t[n] = true
        end
      end
      return t
    end
    local before = names()
    local loaded = false
    vim.api.nvim_create_autocmd("SessionLoadPost", {
      once = true,
      callback = function()
        loaded = true
      end,
    })
    vim.defer_fn(function()
      local changed = false
      if not loaded then
        for n in pairs(names()) do
          if not before[n] then
            changed = true
            break
          end
        end
      end
      if not loaded and not changed then
        Snacks.picker.files()
      end
    end, 250)
    vim.fn.chdir(item.file)
    local s = Snacks.dashboard.sections.session()
    if s then
      pcall(vim.cmd, s.action:sub(2))
    end
  end
  return true
end

install_session_loader()
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  once = true,
  callback = function()
    install_session_loader()
  end,
})
