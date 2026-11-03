-- Statusline: flat blocks with no separators.
--
-- Separators: lualine defaults to `section_separators = { left = "", right = "" }`
-- and `component_separators = { left = "", right = "" }` (lualine/config.lua),
-- i.e. every section ends in a U+E0B0 / U+E0B2 powerline wedge. Clearing both is
-- the whole "clean square" change: the edge becomes a hard colour step, no glyph
-- to render, so it does not depend on the installed nerd-font build.
--
-- Colours: `theme = "auto"` (LazyVim's setting) already resolves to lualine's
-- bundled `lua/lualine/themes/everforest.lua`, because with `colors_name =
-- "everforest"` the auto theme loader tries `load_theme("everforest")` first and
-- only falls back to generating one from highlight groups if that fails. That
-- bundled theme is the right one and is left alone:
--
--   normal.a = #a7c080 green  (bg0 #323d43)   <- Everforest's signature green
--   insert.a = #d8caac fg
--   visual.a = #e68183 red,  replace.a = #e39b7b orange,  command.a = #87c095 aqua
--   b/c      = #505a60 / #3c474d
--
-- An earlier revision of this file hand-rolled a palette instead (purple
-- #d699b6 NORMAL on #3d484d), which looked similar but was not Everforest's
-- scheme -- the mode block is green in the real theme.
--
-- The only thing added here is the right-hand clock block, drawn in the theme's
-- own `c` background so it reads as one more flat square.
local function everforest()
  local ok, theme = pcall(require, "lualine.themes.everforest")
  return ok and theme or nil
end

return {
  {
    "nvim-lualine/lualine.nvim",
    opts = function(_, opts)
      opts.options = opts.options or {}
      opts.options.section_separators = { left = "", right = "" }
      opts.options.component_separators = { left = "", right = "" }

      -- Keep `auto` so a colorscheme change still re-resolves; the bundled
      -- everforest theme is what it picks for this colorscheme anyway.
      opts.options.theme = "auto"

      local theme = everforest()
      local bg = theme and theme.normal.c.bg or nil
      local fg = theme and theme.normal.c.fg or nil

      opts.sections.lualine_z = {
        {
          function()
            return " " .. os.date("%R") .. " "
          end,
          color = bg and { fg = bg, bg = fg, gui = "bold" } or nil,
        },
      }
    end,
  },
}
