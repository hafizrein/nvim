# nvim

My Neovim config, built on [LazyVim](https://github.com/LazyVim/LazyVim). Runs on
Windows, Linux and macOS from the same tree; everything platform-specific is
probed at runtime rather than assumed.

## Requirements

- Neovim **0.12+** (`vim.keycode`, `vim.lsp.inlay_hint`, `winborder`)
- **git**, **ripgrep**, **fd** on `PATH` (Snacks pickers and venv-selector use them)
- A **Nerd Font** (icons in the statusline, gutter and file tree)
- Optional: `dotnet` for C#, `pwsh` for the themed terminal

## Install

```bash
# Linux / macOS
git clone https://github.com/hafizrein/nvim ~/.config/nvim

# Windows (PowerShell)
git clone https://github.com/hafizrein/nvim "$env:LOCALAPPDATA\nvim"
```

Then start `nvim`. LazyVim bootstraps itself and installs the plugins from
`lazy-lock.json`. Run `:Lazy restore` after the first start to pin exactly the
tested versions.

## Secrets

**Nothing is stored in this repo.** Both AI completions read
`OLLAMA_CLOUD_API_KEY` from the environment:

```bash
# bash / zsh
export OLLAMA_CLOUD_API_KEY=...
# PowerShell (persists for the user)
setx OLLAMA_CLOUD_API_KEY "..."
```

Without a key the ghost text and inline chat stay silent; everything else works.

## Layout

```
init.lua                 cache relocation (Windows only), lazy bootstrap
lua/config/
  lazy.lua               plugin manager, disabled builtins, perf
  options.lua            editor options
  keymaps.lua            leader maps (OMP pane, terminal)
  autocmds.lua           small fixups
lua/plugins/
  chrome.lua             winbar-less layout, fillchars, single statusline
  gutter.lua             mini.statuscolumn, gitsigns hairlines, cursorline
  colorscheme.lua        everforest
  statusline.lua         lualine, flat blocks
  minimal.lua            bufferline trimmed to a plain bar
  terminal.lua           snacks terminal: themed shell, no title bar, no bg tint
  dotnet.lua             OmniSharp tuned for legacy .NET Framework
  python.lua             pyright/ruff, venv handling for both venv layouts
  flutter.lua            flutter-tools
  minuet.lua             AI ghost text (ollama-cloud)
  codecompanion.lua      AI inline chat + diff review (ollama-cloud)
  omp.lua                Oh My Pi agent integration
  markdown.lua           render-markdown + preview
  review.lua             code review helper
```

## What is tuned, and why

Every non-obvious setting carries a comment with the measurement that justified
it. The ones worth knowing:

| Setting | Reason |
|---|---|
| `matchparen` disabled | 3x the cost of every cursor move on large files (0.63 -> 0.21 ms) |
| `laststatus = 3`, `cmdheight = 0` | one bar at the bottom edge; no chrome mid-screen |
| `fillchars.eob = " "` | end-of-buffer renders as background, not a column of `~` |
| `winminwidth = 1` | the default of 5 makes `CTRL-W <` silently no-op at the floor |
| `cursorlineopt = "number"` | brightens the gutter number, not the whole line |
| gitsigns all `│` | one continuous hairline instead of stacked bars |
| OmniSharp: no code lens, folding, on-type format | none are used; on-type reformatting fights typing |
| `XDG_CACHE_HOME` (Windows only) | `%TEMP%` is reaped, which throws away the bytecode cache |

Windows-specific pieces are guarded with `vim.fn.has("win32")`: the cache
relocation, `cmd.exe` as `'shell'`, `Scripts/python.exe` for venvs, and the
PowerShell profile launch for the terminal.

## AI stack

| Purpose | Plugin | Model |
|---|---|---|
| Ghost text, `Tab` to accept | minuet-ai.nvim | `deepseek-v4.1-flash` |
| Inline chat, diff review | codecompanion.nvim | `deepseek-v4.1-flash` |
| Agent pane | omp.nvim + Oh My Pi | configured in OMP |

Both use ollama-cloud through its OpenAI-compatible endpoint
(`https://ollama.com/v1/chat/completions`). Note the host: `api.ollama.com`
redirects there and the redirect drops the `Authorization` header.

## License

Apache-2.0 (inherited from LazyVim's starter). See [LICENSE](LICENSE).
