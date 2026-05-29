# codereview.nvim – Copilot Instructions

## Build, test, and lint

```sh
make setup   # configure git hooks (one-time)
make lint    # luacheck lua/ plugin/ tests/
make format  # stylua lua/ plugin/ tests/
make test    # busted --run unit tests/
```

Run a single spec file:

```sh
busted --run unit tests/codereview/mr/diff_spec.lua
```

Run tests matching a name pattern:

```sh
busted --run unit tests/ --filter "mr.diff"
```

CI runs `lint`, `format --check`, and `test` on every push/PR to `main`.

## Architecture

```
plugin/codereview.lua      ← Vim user commands (:CodeReview, :CodeReviewAI, …)
lua/codereview/init.lua    ← Public plugin API (M.open, M.ai_review, M.submit, …)
lua/codereview/
  config.lua               ← Centralized config (deep_merge defaults + user opts + validation)
  keymaps.lua              ← Keymap registration (fully remappable, per-buffer)
  git.lua                  ← Git remote detection and parsing
  providers/               ← Platform abstraction layer
    init.lua               ← Auto-detect GitHub vs GitLab from remote URL
    github.lua / gitlab.lua ← Provider implementations (normalized API)
    types.lua              ← Shared normalization functions (normalize_review, normalize_note, …)
  api/
    client.lua             ← Sync HTTP client (plenary.curl)
    async_client.lua       ← Async HTTP client
    auth.lua               ← Token resolution (env var → project config → setup())
  mr/                      ← MR/PR UI (diff viewer, sidebar, comments, threads)
  ai/                      ← AI review orchestration (batching, prompts, subprocess, providers)
  review/                  ← Review session (drafts.lua, session.lua, submit.lua)
  picker/                  ← Telescope / FZF / Snacks integration
  pipeline/                ← CI/CD status and job log viewer
  plan/                    ← Implementation plan generation from branch diff
  ui/                      ← Shared UI (highlights, floats, markdown, spinner)
```

**Data flow for `:CodeReview`:**

1. `mr/list.lua` fetches open MRs/PRs via the provider API
2. `picker/` displays results; user selects one
3. `mr/detail.lua` opens the diff view (tab + sidebar + diff buffer)
4. `mr/diff.lua` renders diffs with inline comment extmarks; state tracked in a buffer-keyed table (`diff.get_state(buf)`)
5. Most commands re-enter via `diff.get_state(buf)` to find the active review state

**Provider pattern:** both `github.lua` and `gitlab.lua` implement the same function signatures. All raw API responses are normalized through `providers/types.lua` before being used elsewhere.

**Config pattern:** `config.get()` returns the merged config. Sub-modules call `require("codereview.config").get()` at call-time (not at module load time) to always get the current value.

## Key conventions

### Documentation

- When introducing a new functionality or module please update the README with a brief description and usage instructions.

### Module structure

All Lua modules use the standard `local M = {}` / `return M` pattern. No OOP classes.

### LuaLS annotations

Public functions and all types are annotated with LuaLS (`---@class`, `---@field`, `---@param`, `---@return`). Keep annotations consistent with implementations. The main `codereview.Config` class lives in `config.lua`.

### Testing

- Tests run outside Neovim via `busted`. The `vim` global is fully stubbed in `tests/unit_helper.lua` — do not use any Neovim runtime API in tests without adding a stub there first.
- `plenary.curl` is stubbed as `_G._plenary_curl_stub`; override its methods in tests to simulate HTTP responses.
- Test files are named `*_spec.lua` and live alongside their source under `tests/codereview/`.

### Style

- **StyLua**: 120 columns, 2-space indent, double quotes preferred, always call parentheses.
- **Luacheck**: LuaJIT std, `vim` global allowed, unused args allowed.
- Run `make format` before committing; CI enforces `stylua --check`.

### `.codereview.nvim` project config file

Parsed by `lua/codereview/config_file.lua` (INI-style, `#` comments). Keys: `platform`, `project`, `base_url`, `token`, `ai_skip_patterns`. This file is per-project and typically gitignored when it contains a token.

### Backward compatibility

`config.setup()` maintains aliases for renamed keys (`gitlab_url → base_url`, `claude_cmd/agent → ai.claude_cli.*`, old `token` key emits a deprecation warning). Preserve this pattern when renaming config keys.
