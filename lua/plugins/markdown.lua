-- Markdown rendering for LazyVim (Windows), tuned for Everforest.
--   * render-markdown.nvim  -> in-buffer rendering. Headings use NO nerd-font
--     icons (so no tofu boxes) and get explicit Everforest-colored highlight
--     groups per level. Lists, code, tables, checkboxes render cleanly.
--   * markdown-preview.nvim -> live HTML preview in your browser.
--     Native Windows opens via cmd.exe; WSL falls back to `wslview`.

-- Per-level heading colors (Everforest medium-dark accents).
local heading_colors = {
  { fg = "#a7c080" }, -- H1 green
  { fg = "#7fbbb3" }, -- H2 blue
  { fg = "#e69875" }, -- H3 orange
  { fg = "#dbbc7f" }, -- H4 yellow
  { fg = "#d699b6" }, -- H5 purple
  { fg = "#e67e80" }, -- H6 red
}
local heading_bg = "#343f44" -- bg1: subtle full-width band

local function apply_heading_highlights()
  if vim.g.colors_name ~= "everforest" then
    return
  end
  for i, c in ipairs(heading_colors) do
    vim.api.nvim_set_hl(0, ("RenderMarkdownH%d"):format(i), { fg = c.fg, bold = true })
    vim.api.nvim_set_hl(0, ("RenderMarkdownH%dBg"):format(i), { bg = heading_bg })
  end
  -- Make bullets / ordered numbers pop in the accent color.
  vim.api.nvim_set_hl(0, "RenderMarkdownBullet", { fg = "#83c092" }) -- aqua
  vim.api.nvim_set_hl(0, "RenderMarkdownDash", { fg = "#7a8478" }) -- grey0
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown", "norg" },
    dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" },
    opts = {
      -- Headings: font-independent. No icons -> '#'s concealed, bold colored
      -- text on a subtle full-width band. Hierarchy via per-level color.
      heading = {
        sign = false,
        icons = {},
        position = "inline",
        width = "full",
        border = false,
      },
      -- Lists: keep universal geometric bullets; ordered lists show real numbers.
      bullet = { sign = false, right_pad = 1 },
      -- Code blocks: full-width background, thin top/bottom border.
      code = { sign = false, style = "full", width = "full", border = "thin" },
      dash = { icon = "─" },
      checkbox = { enabled = true },
      -- Nicer rounded pipe tables.
      pipe_table = { preset = "round" },
    },
    config = function(_, opts)
      require("render-markdown").setup(opts)
      apply_heading_highlights()
      vim.api.nvim_create_autocmd("ColorScheme", {
        callback = apply_heading_highlights,
      })
    end,
  },

  {
    "iamcco/markdown-preview.nvim",
    ft = "markdown",
    cmd = { "MarkdownPreview", "MarkdownPreviewToggle", "MarkdownPreviewStop" },
    build = "cd app && npm install",
    keys = {
      { "<leader>mp", "<cmd>MarkdownPreviewToggle<cr>", desc = "Markdown Preview" },
    },
    init = function()
      vim.g.mkdp_theme = "dark"
      vim.g.mkdp_auto_start = 0
      vim.g.mkdp_auto_close = 1
      vim.g.mkdp_refresh_slow = 0
      if vim.fn.has("wsl") == 1 and vim.fn.executable("wslview") == 1 then
        vim.g.mkdp_browser = "wslview"
      end
    end,
  },
}