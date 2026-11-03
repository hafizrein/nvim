-- Interactive terminal: launch pwsh with the oh-my-posh user profile loaded,
-- mirroring the Windows Terminal setup (which sources
-- ~/.config/powershell/user_profile.ps1). This makes the LazyVim terminal
-- (`<leader>ft`, `<C-/>`, etc.) show your oh-my-posh prompt + aliases.
return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      if vim.fn.executable("pwsh") == 1 then
        local home = os.getenv("USERPROFILE") or os.getenv("HOME") or ""
        local profile = home .. "\\.config\\powershell\\user_profile.ps1"
        if home ~= "" and vim.fn.filereadable(profile) == 1 then
          opts = opts or {}
          opts.terminal = vim.tbl_deep_extend("force", opts.terminal or {}, {
            -- No quotes needed: the path has no spaces. snacks.terminal parses
            -- this string on spaces into { "pwsh", "-NoLogo", "-NoExit",
            -- "-File", "<profile>" } and runs it interactively (real pty),
            -- so PSReadLine/oh-my-posh work as in a normal terminal.
            shell = "pwsh -NoLogo -NoExit -File " .. profile,
          })
        end
      end
      -- Kill the background contrast between the terminal pane and the code
      -- buffer. snacks paints every non-float window with `SnacksNormal`
      -- (win.lua:95 `winhighlight = Normal:SnacksNormal,...`), which resolves to
      -- NormalFloat's background — measured `#3d484d` against the editor's
      -- `#2d353b`, so the terminal reads as a solid lighter block. Pointing the
      -- window's Normal at the buffer's own Normal makes the pane share the
      -- editor background; only the separator line remains.
      opts = opts or {}
      opts.terminal = vim.tbl_deep_extend("force", opts.terminal or {}, {
        win = {
          wo = {
            winhighlight = "Normal:Normal,NormalNC:NormalNC",
            -- snacks fills this in itself when unset (terminal.lua:95-96):
            -- `id .. ": %{get(b:, 'term_title', '')}"`, which renders as
            -- `1: C:\Program Files\WindowsApps\...\pwsh.exe`. `""` is truthy in
            -- Lua, so it survives the `or` and wins — and an empty winbar takes
            -- no row at all, unlike a " " placeholder.
            winbar = "",
          },
        },
      })
      return opts
    end,
  },
}