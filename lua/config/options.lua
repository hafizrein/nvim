-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Skip the python3 provider probe. ftplugin/python.vim runs `has('python3')`
-- on every python file open, which spawns python3.exe (~110ms on this machine).
-- LazyVim does completion via pyright LSP, never python3complete, so the probe
-- is pure waste.
vim.g.loaded_python3_provider = 0

-- Shell used by `:!`, `system()`, and every plugin that shells out
-- (lazygit, gitsigns, pickers' `rg`, formatters via conform, ...).
--
-- Use cmd.exe, NOT pwsh. PowerShell is not the problem here -- every spawn
-- does a full .NET startup. Measured on this machine, `pwsh -NoLogo
-- -NoProfile -Command exit` costs 585-797 ms against 31 ms for
-- `cmd.exe /c exit`; `git status --short` costs 809 ms via pwsh vs 119 ms
-- via cmd for byte-identical output. Since a shell is spawned per call,
-- that is one PowerShell startup added to every git pick, every format,
-- every external command. cmd.exe is a native binary with no runtime to
-- initialise, so `:!` and plugin subprocesses return immediately.
--
-- The Store (MSIX) build was ruled out as the cause: a portable 7.6.7 unzip
-- spawns in the same ~700 ms, so AppX activation is not the cost. Do not
-- switch this back to pwsh expecting a win.
--
-- The interactive terminal is unaffected -- plugins/terminal.lua explicitly
-- launches `pwsh -NoLogo -NoExit -File <profile>`, so the `<leader>ft`/`<C-/>`
-- terminals still get your oh-my-posh prompt, aliases and PSReadLine.
--
-- For the same reason, prefer running commands as argument lists
-- (`vim.fn.system({ "git", "status" })`) rather than through a shell at all.
if vim.fn.has("win32") == 1 and vim.fn.executable("cmd.exe") == 1 then
  vim.opt.shell = "cmd.exe"
  vim.opt.shellcmdflag = "/c"
  vim.opt.shellquote = ""
  vim.opt.shellxquote = ""
end

-- Disable relative numbers globally
vim.opt.relativenumber = false

-- Minimum window width. Default is 5, and at that width `CTRL-W <` (and
-- `<C-Left>`) silently does nothing while `CTRL-W >` keeps working, because
-- there is no room left in one direction only. Measured: at winminwidth=5,
-- decrease 5->5 (no-op) and increase 5->6. Dropping the floor to 1 lets a
-- split shrink to a bare gutter, so narrowing stays possible next to the OMP
-- pane and other vertical splits.
vim.opt.winminwidth = 1

-- Minimal chrome, following olimorris's nvim config (dotfiles
-- `.config/nvim/lua/config.lua`). Each of these removes furniture rather than
-- adding it, so the buffer reads closer to stock Vim.
--
-- cmdheight = 0: he hides the command bar (`vo.cmdheight = 0`). Messages move
-- to a float -- noice is already installed and handles that -- so the editor
-- gains a whole line per window without losing anything.
vim.opt.cmdheight = 0

-- numberwidth = 2: his `vw.numberwidth = 2` vs LazyVim's 4. The gutter is
-- `signcolumn = "yes"` (LazyVim's default), so it keeps its width whether or
-- not signs are present and content does not shift on the first diagnostic.
vim.opt.numberwidth = 2
