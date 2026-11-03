-- olimorris-style window chrome, minus the colourscheme.
--
-- He runs onedarkpro; the look he actually gets is mostly structural, and what
-- is kept here runs on Everforest:
--
--   1. `laststatus = 3`  -- one global statusline at the very bottom, so a
--      split does not paint a bar across the middle of the screen. This is the
--      single biggest reason his buffer reads as "borderless".
--   2. `cmdheight = 0` -- already set in config/options.lua.
--   3. `fillchars` trimmed -- kills `~` past the end of the buffer and the fold
--      column furniture, so empty space is just background.
--
-- NO winbar: he has one, this config had one briefly, and it was removed on
-- request. Turning it back on is a `vim.wo.winbar` string plus the WinBar/WinBarNC
-- highlights -- note Everforest paints `WinBar` with a solid `#3d484d` band, so
-- it needs `bg = "NONE"` or it reads as a filled strip across the top.
--
-- There is no border anywhere in his config: the only `border` key is
-- oil.nvim's float. The "line" above the terminal is snacks' own `borders`
-- table (`top = { "", "─", ... }`), which is already what snacks draws here.
return {
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    opts = function(_, opts)
      -- LazyVim hides the statusline on the starter page by setting
      -- `laststatus = 0` (plugins/ui.lua:76) and restores it from
      -- `g.lualine_laststatus` when lualine loads (line 86). That restore reads
      -- a value captured BEFORE any of this ran, so setting the option in
      -- config/options.lua alone gets overwritten. Writing it here runs after
      -- the restore, and lualine then honours it (it renders one global bar).
      opts.options = opts.options or {}
      opts.options.globalstatus = true
    end,
  },
  {
    "nvim-lualine/lualine.nvim",
    optional = true,
    init = function()
      vim.o.laststatus = 3
    end,
  },
  {
    -- Fillchars: `eob` blank keeps the area past the last line as plain
    -- background instead of a column of `~`; the fold glyphs go because the
    -- foldcolumn is off. `msgsep` draws the one-line rule above the command
    -- area that cmdheight=0 otherwise leaves bare.
    "folke/snacks.nvim",
    optional = true,
    opts = {
      -- Fainter indent guides: no underlined current scope. This is a LOOK
      -- choice, not a speed one — measured on a 2505-line file, 100 CursorMoved
      -- cost 47.8 ms with indent+scope on and 49.9 ms with both off, i.e. the
      -- difference is noise. (indent.lua:509 attaches its own scope listener
      -- regardless of this flag, so it never could have saved the autocmd.)
      indent = { enabled = true, scope = { enabled = false } },
    },
    init = function()
      -- foldopen/foldclose must be exactly one character each, and are omitted
      -- rather than set to "": with `foldcolumn = 0` they are never drawn, and an
      -- empty string is rejected outright (E1511).
      vim.opt.fillchars = {
        eob = " ",
        diff = " ",
        fold = " ",
        foldsep = " ",
        msgsep = "─",
      }
      vim.opt.foldcolumn = "0"
      -- No colorcolumn. olimorris sets `vw.colorcolumn = "80,120"` and those are
      -- the two vertical lines visible in his screenshots, but on this setup they
      -- read as hard cell-wide bars rather than faint margins (the ruler uses
      -- ColorColumn's background, which Everforest fills solidly). Removed on
      -- request — it is a per-user preference, not part of the layout.
      vim.opt.colorcolumn = ""
    end,
  },
}
