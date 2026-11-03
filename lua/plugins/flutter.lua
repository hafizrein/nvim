-- Flutter / Dart support for everything this machine has: LSP, formatting, debugging,
-- running with hot reload, devices/emulators, DevTools.
--
-- WHY THIS FILE REPLACES THE `lazyvim.plugins.extras.lang.dart` EXTRA
-- That extra configures `dartls` through `nvim-lspconfig`. flutter-tools.nvim starts the
-- *same* analysis server itself, but as `dart language-server --protocol=lsp` with the
-- handlers that implement closing labels, the widget outline, widget guides and
-- `dart/textDocument/super`. Configuring both runs two analysis servers over one project
-- and neither owns the buffer attachments, which is why upstream says explicitly:
-- do NOT also configure `dartls` with lspconfig.
-- So the extra is gone from `lazyvim.json` (replaced by `dap.core`, which the extra did not
-- pull in and flutter-tools needs for debugging), and `dartls` is disabled below as
-- belt-and-braces against the extra being re-enabled from the LazyExtras UI.
-- The dart treesitter parser and `dart format` are kept: both are independent of the LSP.
--
-- The Flutter SDK itself is a prerequisite, not something this config installs:
-- `flutter`/`dart` must be on PATH (or set `flutter_path` below). `flutter-tools` resolves
-- the Dart SDK from the Flutter SDK's own `bin/cache/dart-sdk`, and `dartls` runs
-- `dart language-server` — one SDK for LSP, `dart format`, `flutter run` and the debug
-- adapter, so there is no second Dart install to keep in sync.

return {
  -- nvim-dap + dap-ui + nvim-dap-virtual-text + mason-nvim-dap.
  { import = "lazyvim.plugins.extras.dap.core" },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- flutter-tools.nvim owns the Dart analysis server; see note above.
        dartls = { enabled = false },
      },
    },
  },

  {
    "nvim-treesitter/nvim-treesitter",
    opts = { ensure_installed = { "dart" } },
  },

  -- `dart format` (the SDK's own formatter, so `analysis_options.yaml` is respected).
  -- `stdin = false` in conform's definition means the file is formatted in place and
  -- reloaded, which is why the formatter must be on the same SDK version as the analyzer.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        dart = { "dart_format" },
      },
    },
  },

  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      -- flutter-tools registers a `dart` adapter (the SDK's own `flutter debug-adapter`,
      -- with dartSdkPath/flutterSdkPath taken from the resolved SDK) and its launch
      -- configurations. mason-nvim-dap's automatic installation installs a package for
      -- every key in `dap.adapters`, so it would pull the ~100 MB `dart-debug-adapter`
      -- package for an adapter that is already registered -- and if that package were
      -- later used, its `dart-debug-adapter flutter` command resolves the SDK from PATH
      -- instead of from what flutter-tools resolved. Exclude it; flutter-tools is the
      -- single source of truth for Dart/Flutter debugging.
      automatic_installation = { exclude = { "dart" } },
    },
  },

  {
    "nvim-flutter/flutter-tools.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    -- Load on the first Dart buffer, and on pubspec.yaml so the plugin's own
    -- "run pub get after saving pubspec.yaml" autocmd works when you open the
    -- project from its pubspec instead of from a .dart file.
    ft = { "dart" },
    event = { "BufReadPost pubspec.yaml" },
    -- stylua: ignore
    keys = {
      { "<leader>F", "", desc = "+flutter" },
      { "<leader>Fm", "<cmd>FlutterCommands<cr>", desc = "Commands" },
      { "<leader>Fc", "<cmd>FlutterRun<cr>", desc = "Run" },
      { "<leader>Fd", "<cmd>FlutterDebug<cr>", desc = "Debug" },
      { "<leader>Fa", "<cmd>FlutterAttach<cr>", desc = "Attach" },
      { "<leader>Fl", "<cmd>FlutterReload<cr>", desc = "Hot Reload" },
      { "<leader>FR", "<cmd>FlutterRestart<cr>", desc = "Hot Restart" },
      { "<leader>Fq", "<cmd>FlutterQuit<cr>", desc = "Quit Session" },
      { "<leader>FD", "<cmd>FlutterDevices<cr>", desc = "Select Device" },
      { "<leader>Fe", "<cmd>FlutterEmulators<cr>", desc = "Start Emulator" },
      { "<leader>Fo", "<cmd>FlutterOutlineToggle<cr>", desc = "Widget Outline" },
      { "<leader>Fv", "<cmd>FlutterVisualDebug<cr>", desc = "Visual Debug" },
      { "<leader>Fw", "<cmd>FlutterWidgetPreview<cr>", desc = "Widget Previewer" },
      { "<leader>Fg", "<cmd>FlutterPubGet<cr>", desc = "Pub Get" },
      { "<leader>Fu", "<cmd>FlutterPubUpgrade<cr>", desc = "Pub Upgrade" },
      { "<leader>Ft", "<cmd>FlutterDevTools<cr>", desc = "DevTools Server" },
      { "<leader>FO", "<cmd>FlutterOpenDevTools<cr>", desc = "Open DevTools" },
      { "<leader>Fp", "<cmd>FlutterCopyProfilerUrl<cr>", desc = "Copy Profiler URL" },
      { "<leader>Fx", "<cmd>FlutterLogToggle<cr>", desc = "Toggle Log" },
      { "<leader>Fs", "<cmd>FlutterLspRestart<cr>", desc = "Restart Dart LSP" },
    },
    opts = {
      -- `flutter`/`dart` come from PATH (scoop shims). Uncomment and point at
      -- <sdk>/bin/flutter.bat if the SDK ever stops being on PATH; setting this takes
      -- priority over PATH lookup, and must NOT be combined with `flutter_lookup_cmd`.
      -- flutter_path = "D:/Scoop/apps/flutter/current/bin/flutter.bat",

      debugger = {
        enabled = true,
        -- nvim-dap stops on nothing by default. "All" makes it break on thrown
        -- exceptions (handled ones included) instead of the app just dying; use
        -- "Unhandled" if that turns out to be too noisy.
        exception_breakpoints = { "All" },
      },
      ui = { border = "rounded" },
      widget_guides = { enabled = true },
      dev_log = { enabled = true, notify_errors = true },
      lsp = {
        -- Passed straight to the Dart analysis server as its `dart` settings.
        settings = {
          completeFunctionCalls = true,
          renameFilesWithClasses = "always",
          updateImportsOnRename = true,
          -- dartls turns `// TODO:` comments into diagnostics. LazyVim already
          -- surfaces those via todo-comments.nvim, so the squiggles are noise.
          showTodos = false,
        },
      },
    },
  },
}
