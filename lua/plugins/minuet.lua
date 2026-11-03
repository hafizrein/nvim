-- Ollama Cloud inline completion (ghost text + <Tab> accept), Copilot-style.
--
-- Provider is Ollama Cloud over its OpenAI-compatible endpoint, NOT the native
-- /api/chat one: minuet only speaks OpenAI shape, and `ollama.com/v1/chat/...`
-- accepts `Authorization: Bearer <key>` with the same key OMP already stores.
-- Note the host: `api.ollama.com/v1/...` 301-redirects to `ollama.com`, and the
-- redirect drops the Authorization header (401), so go to ollama.com directly.
--
-- `reasoning_effort = "none"` is load-bearing, not tuning. deepseek-v4.1-flash
-- thinks before answering, and with thinking on it spent the whole max_tokens
-- budget reasoning and returned an EMPTY completion. Measured on this machine:
--   thinking on : 1236 ms TTFT, empty output
--   thinking off:  534 ms TTFT, correct code
-- That is also why the model is the flash tier and not kimi-k2.7-code (940 ms).
--
-- The key is read from OLLAMA_CLOUD_API_KEY, never written here: minuet treats a
-- bare string as an env var name and passes a function's result straight through,
-- so a literal key in this file would be sent verbatim as the "env var name".
return {
  {
    "milanglacier/minuet-ai.nvim",
    event = "InsertEnter",
    config = function()
      require("minuet").setup({
        provider = "openai_compatible",
        -- 3 variants, cycled with one key below. On this provider that is ONE
        -- request (openai_base's chat path hardcodes n_requests = 1 and asks
        -- the model for several options in one prompt) — unlike the FIM path,
        -- which spawns one curl process per completion. So cycling costs output
        -- tokens, not extra round-trips.
        n_completions = 3,
        -- Characters of surrounding buffer sent as context. 16000 (the default)
        -- is far more than a completion needs and costs latency on every
        -- request; this is a network model, not a local one.
        context_window = 4000,
        -- Requests are cheap but not free: coalesce keystrokes before asking.
        debounce = 300,
        throttle = 800,
        request_timeout = 3,
        provider_options = {
          openai_compatible = {
            name = "Ollama Cloud",
            end_point = "https://ollama.com/v1/chat/completions",
            model = "deepseek-v4.1-flash",
            api_key = "OLLAMA_CLOUD_API_KEY",
            stream = true,
            optional = {
              reasoning_effort = "none",
              temperature = 0.2,
              max_tokens = 128,
            },
          },
        },
        -- Ghost text, Copilot-style. `next` cycles variants; minuet's advance()
        -- wraps (% #suggestions), so a single key reaches all of them — no
        -- separate prev binding needed.
        --
        -- Why only this one key is bound here while <Tab> is wrapped below:
        -- minuet's actions are non-expr and several return early, so binding
        -- them directly would swallow the key. <C-l> is chosen because it has
        -- no standalone insert-mode meaning (CTRL-L appears only inside
        -- CTRL-X CTRL-L, per :help insert.txt) and no blink/LazyVim binding in
        -- insert mode (LazyVim uses it for window-right in normal mode only).
        --
        -- Rejected, each collides with something that already mattered:
        --   <C-y>  blink's select_and_accept (LazyVim) + i_CTRL-Y builtin
        --   <C-e>  blink's menu cancel + i_CTRL-E builtin
        --   <C-k>  i_CTRL-K digraph
        --   <A-*>  never delivered on Windows Terminal (Alt arrives as ESC+key,
        --          so <A-y> left insert mode and started a yank)
        virtualtext = {
          auto_trigger_ft = { "cs", "lua", "python", "javascript", "typescript", "json", "yaml", "sh" },
          keymap = {
            next = "<C-l>",
          },
        },
        -- blink.cmp has ghost_text disabled by default (vim.g.ai_cmp is nil), so
        -- the virtual text above is the only ghost text in the buffer.
      })

      -- <Tab>: accept the visible suggestion, else fall through to whatever
      -- held <Tab> before (blink's snippet jump, or a literal tab).
      --
      -- Two details are load-bearing:
      --
      -- 1. blink's <Tab> is an EXPR mapping — it returns the key text to feed
      --    ("\t"). A non-expr wrapper that merely *calls* it discards that
      --    return value and Tab does nothing. So the wrapper is expr too, and
      --    hands back whatever the previous mapping returned.
      -- 2. InsertEnter cannot be used to install this: the plugin is loaded
      --    *by* InsertEnter, and an autocmd created during an event does not
      --    run for that same event, so the first insert would keep blink's Tab.
      --    ModeChanged fires after every InsertEnter handler has run.
      local function wrap_tab()
        local cur = vim.fn.maparg("<Tab>", "i", false, true)
        if type(cur) == "table" and cur.desc == "Minuet accept (else Tab)" then
          return -- already ours
        end
        local prev_cb = type(cur) == "table" and cur.callback or nil
        vim.keymap.set("i", "<Tab>", function()
          local vt = require("minuet.virtualtext")
          if vt.action.is_visible() then
            vt.action.accept()
            return ""
          end
          if prev_cb then
            -- Forward the value: for blink this is "\t" (or "" when it
            -- consumed the key), which is exactly what makes indentation and
            -- snippet jumps keep working.
            local ok, ret = pcall(prev_cb)
            if ok and type(ret) == "string" then
              return ret
            end
            return "\t"
          end
          return "\t"
        end, { expr = true, desc = "Minuet accept (else Tab)" })
      end

      vim.api.nvim_create_autocmd("ModeChanged", {
        pattern = "*:[iR]",
        group = vim.api.nvim_create_augroup("MinuetTabAccept", { clear = true }),
        callback = function()
          -- Deferred: blink.cmp binds <Tab> from its own InsertEnter handler,
          -- which may still be queued when ModeChanged fires.
          vim.schedule(wrap_tab)
        end,
      })

      -- This plugin is loaded *by* InsertEnter, so the autocmd above cannot
      -- fire for the insert that triggered the load: ModeChanged has already
      -- run by the time config() executes. Wrap eagerly, retrying briefly, so
      -- the very first insert gets it too. The retry exists because blink's
      -- own <Tab> binding may land a tick later and overwrite ours.
      local attempts = 0
      local function try_wrap()
        attempts = attempts + 1
        wrap_tab()
        local cur = vim.fn.maparg("<Tab>", "i", false, true)
        local ours = type(cur) == "table" and cur.desc == "Minuet accept (else Tab)"
        if not ours and attempts < 30 then
          vim.defer_fn(try_wrap, 40)
        end
      end
      vim.schedule(try_wrap)
    end,
  },
}
