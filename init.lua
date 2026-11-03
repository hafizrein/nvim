-- Move Neovim's cache (the Lua bytecode cache used by vim.loader) out of %TEMP%.
-- Neovim's stdpath("cache") on Windows is %TEMP%\nvim, and Windows Disk Cleanup /
-- Storage Sense deletes it, so the ~730 .luac files are periodically thrown away
-- and regenerated (measured ~11 ms extra on the first start after a cleanup, and
-- ~90 files rewritten). Putting it under nvim-data keeps it warm.
--
-- Windows only: on Linux/macOS the default cache dir is already persistent, and
-- moving it would silently relocate XDG_CACHE_HOME for every child process.
if vim.fn.has("win32") == 1 and not vim.env.XDG_CACHE_HOME then
  vim.env.XDG_CACHE_HOME = vim.fn.stdpath("state") .. "/cache"
end

-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")
