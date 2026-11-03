-- Buffer tab bar: back on, but clean.
--
-- olimorris's config has no tab bar at all, and switching it off left you with no
-- way to see what is open, so it stays on -- just without the furniture that made
-- it look like an IDE.
--
-- What changes from LazyVim's defaults (bufferline/config.lua `get_defaults()`):
--   separator_style = { "", "" }   was "thin" (U+258F / U+2595 half-block bars)
--   indicator.style = "underline"  was "icon" (the U+258E bar on the current buffer)
--   show_close_icon = false        was true -- the trailing U+2715 on the bar
--   show_buffer_close_icons=false  was true -- the per-buffer close glyph
--   show_tab_indicators = false    was true
--
-- `always_show_bufferline` is set true here, overriding LazyVim's false. With
-- false the bar only draws when more than one buffer is listed
-- (bufferline.lua:93), and because custom_filter below removes the scratch
-- buffer, a single open file left the count at 1 and the bar vanished.
--
-- custom_filter drops unnamed/scratch buffers: snacks creates one named
-- "[Scratch]", and an empty buffer has no path to show, so neither belongs in a
-- bar whose job is "which files are open". `buflisted` is the check bufferline
-- itself uses to decide what counts as a buffer.
return {
  {
    "akinsho/bufferline.nvim",
    opts = {
      options = {
        always_show_bufferline = true,
        separator_style = { "", "" },
        indicator = { style = "underline" },
        show_close_icon = false,
        show_buffer_close_icons = false,
        show_tab_indicators = false,
        custom_filter = function(buf, _)
          if not vim.bo[buf].buflisted then
            return false
          end
          local name = vim.api.nvim_buf_get_name(buf)
          if name == "" then
            return false
          end
          return vim.bo[buf].buftype == ""
        end,
      },
    },
  },
}
