-- Inline chat: select code, prompt it, review a diff, accept hunks.
--
-- This is the one thing neither OMP nor minuet covers. OMP is a chat pane (it
-- never writes into your buffer), and minuet only predicts ahead of the cursor.
-- CodeCompanion's *inline* interaction edits the buffer directly per prompt —
-- the Cursor "Cmd-K" / Copilot-inline shape.
--
-- Only the inline interaction is wired here. The chat buffer would duplicate
-- OMP, so it is left at its default rather than promoted to the keymaps.
--
-- Preconditions verified against ollama-cloud before installing:
--   * tool calling works — the inline interaction edits through the edit_file
--     tool, so a model without tool_calls cannot drive it at all. Measured:
--     finish_reason "tool_calls", status 200.
--   * latency is acceptable for an interactive edit — deepseek-v4.1-flash
--     TTFT 640 ms, 486-char edit done in 1025 ms. kimi-k2.7-code was 1434/2019.
--
-- The adapter is `openai_compatible`, NOT the built-in `ollama` adapter: that
-- one posts to `${url}/api/chat` with no auth header, so it cannot reach a
-- hosted ollama at all. ollama-cloud speaks OpenAI chat completions at
-- https://ollama.com/v1/chat/completions, which is what this extends.
return {
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
    cmd = { "CodeCompanion", "CodeCompanionChat", "CodeCompanionActions" },
    keys = {
      -- Visual mode: prompt against the selection only.
      {
        "<leader>ai",
        ":CodeCompanion<CR>",
        mode = "v",
        desc = "Inline chat (selection)",
      },
      -- Normal mode: prompt against the buffer.
      {
        "<leader>ai",
        ":CodeCompanion<CR>",
        mode = "n",
        desc = "Inline chat (buffer)",
      },
    },
    opts = {
      adapters = {
        http = {
          ollama_cloud = function()
            return require("codecompanion.adapters").extend("openai_compatible", {
              formatted_name = "Ollama Cloud",
              env = {
                -- Base URL WITHOUT /v1: the adapter appends /v1/chat/completions
                -- itself. `url` is resolved per request, so the key stays in the
                -- environment and never enters this file.
                url = "https://ollama.com",
                api_key = "OLLAMA_CLOUD_API_KEY",
              },
              schema = {
                model = {
                  -- Both set explicitly so the /v1/models endpoint is never
                  -- called: ollama.com's list is a catalogue, not this account's
                  -- entitlements, and the first entry would be an arbitrary pick.
                  default = "deepseek-v4.1-flash",
                  choices = { "deepseek-v4.1-flash", "kimi-k2.7-code" },
                },
              },
              -- Sent on every request. Without it the model answers with a
              -- `reasoning` delta first and spends the token budget thinking
              -- instead of editing; the same switch was worth ~700 ms and a
              -- correct (rather than empty) completion on the minuet side.
              -- Verified it survives map_schema_to_params() into the body.
              parameters = { reasoning_effort = "none" },
            })
          end,
        },
      },
      interactions = {
        inline = {
          adapter = "ollama_cloud",
          opts = {
            -- The inline interaction sends the whole buffer by default. Half of
            -- that is plenty for an edit and keeps the round-trip short.
            max_context_tokens = 8000,
          },
        },
      },
      -- Edits land as a diff you accept hunk by hunk: g1/g2/g3 accept all,
      -- accept under cursor, reject under cursor. Left at defaults.
      display = {
        diff = { enabled = true },
      },
    },
  },
}
