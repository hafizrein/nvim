-- Global C# / .NET setup. Applies to every C# project on this machine.
--
-- DIAGNOSTIC SUPPRESSION (2026-09-25). The repo enforces TreatWarningsAsErrors plus
-- AnalysisLevel=latest-recommended, so OmniSharp's diagnostic set is noisy in the editor;
-- the build is the source of truth for warnings, not the LSP.
--
-- What is suppressed, and what deliberately is NOT:
--   1. publishDiagnostics swallowed -> no warning/error diagnostics in the editor.
--      THIS is what removes the squiggles.
--   3. semanticTokens provider off -> no LSP token *underlines*.
--   NOT DONE: syntax/treesitter are left ALONE. An earlier attempt set
--   `syntax = "off"` and stopped the treesitter highlighter to kill squiggles, which
--   also killed **all syntax colours** on every .cs buffer. Diagnostics suppression
--   does not require touching the highlighter — do not re-add it.
--
-- 1) VSToolsPath -- legacy (non-SDK) ASP.NET projects would not load.
--    Legacy .NET Framework projects (MVC5-era .csproj) end with
--      <Import Project="$(VSToolsPath)\WebApplications\Microsoft.WebApplication.targets" />
--    That file ships only with Visual Studio, but OmniSharp runs MSBuild from the
--    .NET SDK (C:\Program Files\dotnet\sdk\<ver>), so $(VSToolsPath) points inside
--    the SDK directory, the import fails with MSB4019, and the .csproj is silently
--    dropped from the workspace. The server still attaches and answers navigation
--    with "No document found" -> gd/gr/hover show "No information available".
--    Resolved per project so this works on any machine/VS edition.
--
-- 2) root_dir gate -- OmniSharp's own metadata buffers are not workspace files.
--    Jumping into a framework type (ApiController, ...) opens a buffer named
--      <drive>:\$metadata$\Project\<proj>\Assembly\...\ApiController.cs
--    That path is outside any solution, so the *.sln/*.csproj root markers do not
--    match and lspconfig starts a SECOND OmniSharp rooted at the drive. It serves
--    no project, rejects every request ("document not in workspace"), and the
--    resulting churn makes nvim terminate the LSP transport on
--    INVALID_SERVER_MESSAGE. Refusing a root dir for those buffers prevents it.
--
-- 3) Orphaned OmniSharp servers.
--    lspconfig starts OmniSharp through the mason shim, so the process nvim owns
--    is `cmd.exe` and the actual server is its `dotnet.exe` child:
--        cmd.exe (nvim's child)  ->  dotnet.exe (the real OmniSharp)
--    When nvim stops the client it signals the process it spawned -- the shim --
--    so the dotnet server survives :q/:qa/:wqa and piles up, each holding
--    hundreds of MB, which then slows every subsequent session. (OmniSharp's
--    --hostPID watchdog only covers nvim dying uncleanly, which is why a hard
--    kill left nothing behind while a normal quit did.)
--    Launching `dotnet <OmniSharp.dll>` directly makes the server itself nvim's
--    child, so shutdown reaches it. exit_timeout then gives nvim permission to
--    force-stop rather than only asking nicely.
return {
  {
    "neovim/nvim-lspconfig",
    opts = function(_, opts)
      -- Locate a Visual Studio install that ships Microsoft.WebApplication.targets.
      -- Globbed rather than hard-coded so this works across VS editions/versions.
      local function find_vstools()
        for _, base in ipairs({
          "C:/Program Files/Microsoft Visual Studio",
          "C:/Program Files (x86)/Microsoft Visual Studio",
        }) do
          local hits = vim.fn.glob(
            base .. "/*/*/MSBuild/Microsoft/VisualStudio/v*/WebApplications/Microsoft.WebApplication.targets",
            false,
            true
          )
          if #hits > 0 then
            -- strip "/WebApplications/Microsoft.WebApplication.targets"
            return vim.fn.fnamemodify(hits[1], ":h:h")
          end
        end
      end

      local vstools = find_vstools()
      if not vstools then
        vim.notify(
          "omnisharp: Microsoft.WebApplication.targets not found; legacy .NET Framework projects will fail to load",
          vim.log.levels.WARN
        )
      end

      local root_pattern = require("lspconfig.util").root_pattern

      -- Run the server itself instead of the mason shim, so that stopping the
      -- client actually stops OmniSharp (see note 3 above). The shim wraps
      -- `dotnet <OmniSharp.dll>`, and nvim would only ever signal the shim.
      -- Keep the stock args (--languageserver etc.); only the executable changes.
      local omnisharp_dll = vim.fn.glob(
        vim.fn.stdpath("data") .. "/mason/packages/omnisharp/libexec/OmniSharp.dll"
      )
      local stock = vim.api.nvim_get_runtime_file("lsp/omnisharp.lua", false)[1]
      local stock_args = stock and dofile(stock).cmd or nil
      local cmd = nil
      if omnisharp_dll ~= "" and stock_args then
        cmd = { "dotnet", omnisharp_dll }
        -- drop the shim name (element 1), keep every flag
        for i = 2, #stock_args do
          cmd[#cmd + 1] = stock_args[i]
        end
      end

      -- Applies to every C# project, not just one solution.
      opts.servers = opts.servers or {}
      opts.servers.omnisharp = vim.tbl_deep_extend("force", opts.servers.omnisharp or {}, {
        -- OmniSharp works out which solution to load from the cwd of the process
        -- nvim spawns it with, and nvim defaults that to *nvim's* own cwd
        -- (vim.lsp.client does `cwd = config.cmd_cwd`, nil unless set). lspconfig
        -- passes no `-s <solution>` either, so that cwd is the only thing that
        -- identifies the project. Two consequences, both silent:
        --
        -- 1. Opening a file by absolute path from anywhere else -- from $HOME,
        --    $TEMP, or another project -- pointed OmniSharp at the wrong
        --    directory. Its log:
        --      "No solution files found in 'C:\Users\...\Temp\'"
        --      "Solution initialized -> Initial document count: 0"
        --      "document not in workspace"
        --    and every request (documentSymbol, definition, hover) returned EMPTY
        --    with no error surfaced, so go-to-definition did nothing until you
        --    happened to start nvim from inside the project.
        -- 2. `root_dir` is not always the directory to use. It stops at the
        --    nearest .sln/.csproj going up from the file, so it can land on
        --    the solution folder, but for VMS it lands on VMS\VMS (the csproj)
        --    with VMS.sln one level above -- and starting OmniSharp in the csproj
        --    folder returned nothing for VMS while the solution folder worked.
        --
        -- So the cwd is the nearest ancestor holding a solution, falling back to
        -- root_dir. Verified on both projects with nvim's cwd elsewhere:
        -- VMS each go from `documentSymbol -> 0 items / definition -> {}` to a
        -- resolved location.
        --
        -- Neither `cmd_cwd` nor `on_new_config` can set this: nvim validates
        -- cmd_cwd as a directory *string* and silently drops a function, and
        -- LazyVim drives servers through nvim's native `vim.lsp.config`, which
        -- never calls lspconfig's legacy `on_new_config`. `cmd` as a function is
        -- the supported hook: nvim calls it as `cmd(dispatchers, config)` with the
        -- resolved config and expects an RPC client back, so the spawn is done
        -- explicitly here.
        cmd = function(dispatchers, config)
          -- Nearest ancestor holding a solution is not enough: projects/VMS has a
          -- stale VMS\VMSAPI.sln that points at a VMSAPI.csproj which no longer
          -- exists, so loading *it* yields no projects and OmniSharp answers
          -- nothing again. The outermost solution in the repo (VMS.sln) is the one
          -- that references the real VMS\VMS.csproj. So walk up to the repo root
          -- (a .git directory) and take the last solution found.
          local function solution_dir(from)
            if not from or from == "" then
              return nil
            end
            -- normalize first: fnamemodify(path, ":h") on a Windows path ending in
            -- a separator (":p" adds one) just strips that separator and returns
            -- the *same* directory, so the walk never leaves the starting folder.
            local dir = vim.fs.normalize(vim.fn.fnamemodify(from, ":p"))
            local found ---@type string?
            for _ = 1, 8 do
              local sln = vim.fn.glob(dir .. "/*.slnx", false, true)[1] or vim.fn.glob(dir .. "/*.sln", false, true)[1]
              if sln then
                found = dir
              end
              if vim.fn.isdirectory(dir .. "/.git") == 1 then
                break -- repo root: nothing above this belongs to the project
              end
              local parent = vim.fs.dirname(dir)
              if parent == dir or not parent or parent == "" then
                break
              end
              dir = parent
            end
            return found
          end
          local cwd = solution_dir(config.root_dir) or config.root_dir or config.cmd_cwd
          return vim.lsp.rpc.start(cmd, dispatchers, {
            cwd = cwd,
            env = vstools and { VSToolsPath = vstools } or nil,
          })
        end,
        cmd_env = vstools and { VSToolsPath = vstools } or nil,

        -- Give nvim a chance to shut the server down, then force-stop it, so
        -- OmniSharp does not outlive the editor and pile up.
        exit_timeout = 5000,

        root_dir = function(bufnr, on_dir)
          local fname = vim.api.nvim_buf_get_name(bufnr)
          if fname:find("$metadata$", 1, true) or fname:find("$generated$", 1, true) then
            return
          end
          on_dir(
            root_pattern("*.slnx")(fname)
              or root_pattern("*.sln")(fname)
              or root_pattern("*.csproj")(fname)
              or root_pattern("omnisharp.json")(fname)
              or root_pattern("function.json")(fname)
          )
        end,

        -- Decompilation so jumps into framework types resolve to real source.
        -- Deliberately NOT enabling EnableAnalyzersSupport/EnableImportCompletion:
        -- they measured ~11x more diagnostics (805 vs 74 on one file) for no benefit.
        -- (Note: OmniSharp still emits its DEFAULT diagnostic set without them, which is
        -- why layer 1 below is required rather than merely nice to have.)

        -- ===== DIAGNOSTICS SUPPRESSED: warnings/errors never reach the editor =====
        -- Colours are untouched: this hooks the diagnostic channel only.
        handlers = {
          ["textDocument/publishDiagnostics"] = function() end,
        },

        -- ===== no semantic-token underlines (token colours come from treesitter) =====
        capabilities = (function()
          local caps = vim.lsp.protocol.make_client_capabilities()
          caps.semanticTokensProvider = nil
          return caps
        end)(),

        -- Two server capabilities this setup has no use for. Declined here, so
        -- OmniSharp never sends them rather than sending and discarding:
        --   * codeLensProvider     -- inline "N references" widget per method
        --   * foldingRangeProvider -- unused; foldmethod is expr, nothing calls it
        -- NOTE ON SPEED: I measured this expecting a win and could NOT prove one.
        -- Median of 7 samples x 25 cursor moves with forced redraw on
        -- a 2505-line C# file: 57.6 ms before, 60.5 ms after. The
        -- apparent 40 ms run was noise; repeat runs on the same code varied
        -- 110-206 ms. So this is a no-loss cleanup, not a speed fix.
        on_init = function(client)
          client.server_capabilities.codeLensProvider = nil
          client.server_capabilities.foldingRangeProvider = nil
          -- On-type formatting (OmniSharp reformats after every `}`, `;` and
          -- newline). Also NOT a proven speed win: 20 synthetic insert events
          -- measured 333 ms with it and 270 ms without on one run, but 318 ms
          -- after disabling it on another — i.e. inside the noise band. It is
          -- off because it is unwanted, not because it was measured faster:
          -- reformatting mid-sentence fights you while typing, and formatting
          -- is still available on demand via `<leader>cf`.
          client.server_capabilities.documentOnTypeFormattingProvider = nil
          return true
        end,

        settings = {
          RoslynExtensionsOptions = {
            EnableDecompilationSupport = true,
          },
        },
      })
      return opts
    end,
  },
}
