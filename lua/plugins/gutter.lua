-- Gutter: the last structural difference from olimorris's look.
--
-- Side-by-side, his left column is: number, then one thin │ for git, and the
-- current line's number is the only one that is not dimmed. Yours had:
--
--   * LazyVim's statuscolumn (`%!v:lua.LazyVim.statuscolumn()`) drawing its own
--     sign area, plus gitsigns signs drawn as wide glyphs ("▎" / "") instead of
--     a hairline;
--   * `cursorlineopt = "both"` highlighting the whole screen line, so the
--     cursor line reads as a filled band rather than a brighter number;
--   * `listchars = "tab:> ,trail:-,nbsp:+"` painting `>` and `-` into the text,
--     where he uses `» ` and `·`.
--
-- He reaches his version with mini.statuscolumn (his plugin/statuscolumn.lua)
-- plus a gitsigns block setting every sign to the same `│`. Both reproduced
-- here; mini.statuscolumn is not a LazyVim dependency, so it is added.
return {
  {
    "nvim-mini/mini.statuscolumn",
    version = false,
    event = { "BufReadPost", "BufNewFile" },
    opts = function()
      local api, v = vim.api, vim.v
      local MiniStatuscolumn = require("mini.statuscolumn")
      local git_ns = api.nvim_create_namespace("gitsigns_signs_")

      ---Highest-priority non-git sign on a line, if any
      ---@param lnum number
      ---@return table|nil
      local function sign_at(lnum)
        local marks = api.nvim_buf_get_extmarks(0, -1, { lnum - 1, 0 }, { lnum - 1, -1 }, {
          details = true,
          type = "sign",
        })
        local out
        for _, mark in ipairs(marks) do
          local sign = mark[4]
          if sign.sign_text and sign.ns_id ~= git_ns and (out == nil or (sign.priority or 0) > (out.priority or 0)) then
            out = sign
          end
        end
        return out
      end

      -- Every gitsigns sign is the same `│` (see the gitsigns block below), so
      -- the separator does not need to look up which kind of change is there:
      -- presence of any git extmark on the line is enough to draw the bar.
      ---@return string
      local function git_separator()
        local mark = api.nvim_buf_get_extmarks(0, git_ns, { v.lnum - 1, 0 }, { v.lnum - 1, -1 }, { limit = 1 })[1]
        if not mark then
          return "%#SignColumn# "
        end
        local hl = require("gitsigns.config").config.signs.add.hl or "GitSignsAdd"
        return "%#" .. hl .. "#│"
      end

      local ignored_buftypes = { "prompt", "help", "quickfix", "terminal" }
      local ignored_filetypes = { "lspinfo", "snacks_dashboard", "minuet" }

      local function guard(render)
        return function(data)
          local buf = data.buf_id
          if not buf or not api.nvim_buf_is_valid(buf) then
            return ""
          end
          if vim.tbl_contains(ignored_buftypes, vim.bo[buf].buftype) then
            return ""
          end
          if vim.tbl_contains(ignored_filetypes, vim.bo[buf].filetype) then
            return ""
          end
          return render(data)
        end
      end

      local content = MiniStatuscolumn.gen_content.main({
        {
          format = "s=lf",
          lnum = "%l ",
          sign = "%{%v:lua.MiniStatuscolumnSign()%}",
          sep = "%{%v:lua.MiniStatuscolumnGit()%}",
        },
        { ltype = "virt", lnum = "", sign = "  " },
        { ltype = "wrap", lnum = "", sign = "  " },
        { pos = "cursor", ltype = "text", lnum = "%#CursorLineNr#%{&nu ? v:lnum : ''} " },
      })

      -- Statuscolumn strings are evaluated by Vim, so the callbacks have to be
      -- reachable from a global.
      _G.MiniStatuscolumnSign = function()
        local sign = sign_at(v.lnum)
        if not sign then
          return "%#SignColumn#  "
        end
        return "%#" .. (sign.sign_hl_group or "SignColumn") .. "#" .. sign.sign_text
      end
      _G.MiniStatuscolumnGit = git_separator

      return {
        content = { active = guard(content.active), inactive = guard(content.inactive) },
        dim_inactive = false,
      }
    end,
  },
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      -- Every sign the same hairline, so the column is one continuous │ instead
      -- of LazyVim's wide bars. This is the most visible part of his gutter.
      signs = {
        add = { text = "│" },
        change = { text = "│" },
        delete = { text = "│" },
        topdelete = { text = "│" },
        changedelete = { text = "│" },
        untracked = { text = "│" },
      },
      signs_staged_enable = false,
      numhl = false,
      linehl = false,
    },
  },
  {
    "neovim/nvim-lspconfig",
    optional = true,
    init = function()
      -- Cursor line: highlight only the number, not the whole screen line. With
      -- "both" the cursor line is a filled band across the buffer; his reads as
      -- a brighter gutter entry.
      vim.opt.cursorlineopt = "number"
      -- `list` stays on (useful for trailing whitespace) but with his glyphs: a
      -- `» ` for tabs and `·` for trailing space. `>` and `-` look like text.
      vim.opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
    end,
  },
}
