# nvim

Personal Neovim config on [LazyVim](https://github.com/LazyVim/LazyVim). One tree
for Windows, Linux and macOS — platform-specific behaviour is probed at runtime,
never assumed.

> **Why this repo exists:** most configs are shared as a screenshot and a pile of
> plugins. This one is annotated with the measurement or the failure that
> justified each non-obvious setting, including the attempts that made things
> *worse*. If you are here to copy something, the comments tell you whether it
> will help on your machine.

## Requirements

| Need | Why |
|---|---|
| Neovim **0.12+** | `vim.keycode`, `vim.lsp.inlay_hint`, `winborder` |
| `git`, `ripgrep`, `fd` | Snacks pickers, venv-selector |
| A Nerd Font | icons in the statusline, gutter, file tree |
| Optional: `dotnet` | C# (OmniSharp) |
| Optional: `pwsh` | themed terminal; falls back to your default shell |
| Optional: `flutter`/`dart` on `PATH` | Flutter support |

## Install

```bash
# Linux / macOS
git clone https://github.com/hafizrein/nvim ~/.config/nvim

# Windows (PowerShell)
git clone https://github.com/hafizrein/nvim "$env:LOCALAPPDATA\nvim"
```

Start `nvim`; LazyVim bootstraps and installs from `lazy-lock.json`. Then:

```vim
:Lazy restore   " pin exact tested versions
:Mason          " install LSP servers (not shipped in this repo)
```

## Secrets

**Nothing is stored here.** Both AI features read `OLLAMA_CLOUD_API_KEY` from
the environment:

```bash
export OLLAMA_CLOUD_API_KEY=...          # bash / zsh
setx OLLAMA_CLOUD_API_KEY "..."          # PowerShell, persists
```

Without a key the ghost text and inline chat stay quiet; everything else works.

## Keys

Leader is <kbd>Space</kbd>.

| Key | Mode | Action |
|---|---|---|
| `<leader>h` | n | Dashboard |
| `<leader>ao` | n, v | Toggle the Oh My Pi agent pane (right, 40%) |
| `<leader>fv` | n | Terminal, right split |
| `<leader>ai` | n | Inline chat against the buffer |
| `<leader>ai` | v | Inline chat against the selection |
| `<leader>cv` | n | Select Python virtualenv |
| `<leader>cf` | n, v | Format (LazyVim) |
| `<Tab>` | i | Accept AI ghost text; otherwise normal Tab |
| `<C-l>` | i | Cycle to the next AI suggestion |
| `jk` | t | Leave terminal mode |
| `<C-h/j/k/l>` | n | Move between windows |

Diff review (appears only while a CodeCompanion edit is pending): `}`/`{` step
hunks, `ga` accept, `gr` reject, `g2`/`g3` accept/reject the rest, `u` undo.
Input box: `<CR>` send, `q`/`<Esc>` close keeping text, `<Up>` continue the
conversation, `ga` switch adapter/model.

## Layout

```
init.lua                 cache relocation (Windows only), lazy bootstrap
lua/config/
  lazy.lua               plugin manager, disabled builtins, disabled plugins
  options.lua            editor options
  keymaps.lua            leader maps
  autocmds.lua           small fixups
lua/plugins/
  chrome.lua             single statusline, no winbar, trimmed fillchars
  gutter.lua             mini.statuscolumn, gitsigns hairlines, cursorline
  colorscheme.lua        everforest, loaded once instead of after tokyonight
  statusline.lua         lualine, flat blocks
  minimal.lua            bufferline trimmed to a plain bar
  terminal.lua           snacks terminal: themed shell, no title bar, no tint
  dotnet.lua             OmniSharp, tuned for legacy .NET Framework + modern
  python.lua             pyright/ruff, both venv layouts
  flutter.lua            flutter-tools; dartls deliberately disabled
  minuet.lua             AI ghost text (ollama-cloud)
  codecompanion.lua      AI inline chat + diff review (ollama-cloud)
  omp.lua                Oh My Pi agent integration
  markdown.lua           render-markdown + preview
  review.lua             code review helper
```

## What is tuned, and the evidence

| Setting | Why |
|---|---|
| `matchparen` disabled | **0.63 → 0.21 ms** per cursor move on a 2505-line file. Biggest single win. |
| `laststatus = 3` | One bar at the bottom edge; splits don't paint a bar mid-screen. |
| `cmdheight = 0` | No command row; messages float via noice. |
| `fillchars.eob = " "` | End-of-buffer is background, not a column of `~`. |
| `winminwidth = 1` | At the default 5, `CTRL-W <` silently no-ops while `<` still grows. |
| `cursorlineopt = "number"` | Brightens the gutter number, not a filled band across the line. |
| gitsigns all `│` | One continuous hairline instead of stacked bars. |
| `mini.statuscolumn` | Number + one git column + brighter cursor line. |
| OmniSharp: no code lens, folding, on-type format | Unused. On-type reformatting fights typing. |
| OmniSharp diagnostics: suppressed for **legacy only** | `TreatWarningsAsErrors` makes them noise there; modern SDK projects show them. |
| venv interpreter probed per platform | `Scripts/python.exe` vs `bin/python`; hardcoding one breaks the other. |
| `XDG_CACHE_HOME` (Windows only) | `%TEMP%` is reaped, throwing away the bytecode cache. |

### Things that did NOT work

Kept in the comments so nobody repeats them:

- **Disabling treesitter** to speed up redraws: **55.7 → 88.0 ms**. Regex `syntax`
  is slower than treesitter here.
- **`synmaxcol = 256`**: 55.7 → 56.4 ms. No effect at these line lengths.
- **`foldmethod` manual**: 150.4 → 150.9 ms. Nothing.
- **Code lens / folding as a speed fix**: 57.6 → 60.5 ms. Removed because they
  are unused, *not* because they were measured faster. Earlier "40 ms" reading
  was noise; the same code varies 110–206 ms run to run.
- **`syntax = "off"` to kill squiggles**: kills *all* syntax colour. Suppress the
  diagnostic channel instead.

## AI stack

| Purpose | Plugin | Model |
|---|---|---|
| Ghost text, `<Tab>` to accept | minuet-ai.nvim | `deepseek-v4.1-flash` |
| Inline chat, diff review | codecompanion.nvim | `deepseek-v4.1-flash` |
| Agent pane | omp.nvim + Oh My Pi | configured in OMP |

Both AI plugins use ollama-cloud's OpenAI-compatible endpoint. Three facts worth
knowing if you copy this:

- Use `https://ollama.com/v1/chat/completions`. `api.ollama.com` 301-redirects
  there and the redirect **drops the `Authorization` header** → 401.
- `reasoning_effort = "none"` is load-bearing, not tuning. With thinking on,
  `deepseek-v4.1-flash` spent its whole token budget reasoning and returned an
  **empty** completion (1236 ms). With it off: 534 ms and correct code.
- CodeCompanion's built-in `ollama` adapter posts to `${url}/api/chat` with no
  auth header, so it cannot reach a hosted endpoint. Extend
  `openai_compatible` instead.

## Platform notes

Guarded by `vim.fn.has("win32")`, so the same tree works on POSIX:

- `XDG_CACHE_HOME` relocation (Windows only)
- `cmd.exe` as `'shell'` — measured 31 ms vs 119 ms for `git status` via `pwsh`
- venv interpreter: `Scripts/python.exe` vs `bin/python`
- terminal: PowerShell profile only if `pwsh` exists
- `VSToolsPath`: resolves `VSWHERE`/MSBuild targets for legacy ASP.NET projects

## For agents reading this

- Every non-obvious line carries the reason it exists. Do not "clean up" a
  comment that explains a measured trade-off — the measurement is the point.
- Before changing a perf-related option, measure. Several plausible-sounding
  optimisations in this file made things worse (see above).
- `lua/plugins/dotnet.lua` is the most delicate file: it reimplements the
  OmniSharp spawn (`cmd` as a function) because `cmd_cwd` cannot be a function
  and LazyVim bypasses lspconfig's `on_new_config`. Read the comments there
  before touching it.
- Disabled plugins in `lua/config/lazy.lua` are deliberate; each has a note.

## License

Apache-2.0, inherited from the LazyVim starter. See [LICENSE](LICENSE).
