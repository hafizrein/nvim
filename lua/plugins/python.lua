-- Python support: LSP (pyright + ruff), venv-selector, neotest, debugpy
-- Provides SPC c v (<leader>cv) -> :VenvSelect to pick the project venv
return {
  { import = "lazyvim.plugins.extras.lang.python" },
  {
    "neovim/nvim-lspconfig",
    -- Make pyright always use the project's uv venv (.venv in project root).
    -- venvPath is relative to the workspace root; uv always creates .venv there.
    -- This is deterministic and doesn't depend on venv-selector's LSP restart.
    opts = {
      servers = {
        pyright = {
          settings = {
            python = {
              venvPath = ".",
              venv = ".venv",
            },
          },
          -- Windows pyright only resolves the venv when it also gets an
          -- absolute pythonPath. root_dir is unknown at config time, so set it
          -- in on_init (runs after root resolution) and re-push the settings.
          on_init = function(client, _)
            local root = client.config.root_dir
            if root and vim.fn.isdirectory(root .. "/.venv") == 1 then
              -- Path shape differs per platform: Windows venvs put the
              -- interpreter under Scripts/, POSIX under bin/. Hardcoding Scripts
              -- would break on Linux/macOS, which is why this is probed.
              local rel = vim.fn.has("win32") == 1 and "/.venv/Scripts/python.exe" or "/.venv/bin/python"
              client.settings = vim.tbl_deep_extend("force", client.settings or {}, {
                python = {
                  pythonPath = root .. rel,
                  venvPath = ".",
                  venv = ".venv",
                },
              })
              client:notify("workspace/didChangeConfiguration", { settings = client.settings })
            end
          end,
        },
      },
    },
  },
  {
    "linux-cultist/venv-selector.nvim",
    -- override the extra's keymap: remove ft="python" so it works in ANY file
    keys = {
      { "<leader>cv", "<cmd>:VenvSelect<cr>", desc = "Select VirtualEnv" },
    },
    -- FIX: default Windows searches pass $CWD/$WORKSPACE_PATH/$FILE_DIR unquoted,
    -- which breaks when the project path contains spaces (PowerShell splits on them
    -- and fd dies with "Search path '/home/user/pro' is not a directory").
    -- Quote the path variables. Pattern keeps \\ (regex literal backslash) for
    -- Windows-style paths.
    --
    -- The interpreter path is platform-dependent: Windows venvs use
    -- Scripts\python.exe, POSIX venvs use bin/python. Hardcoding Scripts meant
    -- this search found nothing outside Windows.
    opts = (function()
      local exe = vim.fn.has("win32") == 1 and "Scripts\\\\python.exe" or "bin/python"
      local function cmd(var)
        return string.format('$FD %s$ "%s" --full-path --color never -HI -a -L', exe, var)
      end
      return {
        search = {
          cwd = { command = cmd("$CWD") },
          workspace = { command = cmd("$WORKSPACE_PATH") },
          file = { command = cmd("$FILE_DIR") },
        },
      }
    end)(),
  },
}
