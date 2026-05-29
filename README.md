```
 ██████╗ ██████╗ ██████╗ ███████╗
██╔════╝██╔═══██╗██╔══██╗██╔════╝
██║     ██║   ██║██║  ██║█████╗
██║     ██║   ██║██║  ██║██╔══╝
╚██████╗╚██████╔╝██████╔╝███████╗
 ╚═════╝ ╚═════╝ ╚═════╝ ╚══════╝
██████╗ ███████╗██╗   ██╗██╗███████╗██╗    ██╗
██╔══██╗██╔════╝██║   ██║██║██╔════╝██║    ██║
██████╔╝█████╗  ██║   ██║██║█████╗  ██║ █╗ ██║
██╔══██╗██╔══╝  ╚██╗ ██╔╝██║██╔══╝  ██║███╗██║
██║  ██║███████╗ ╚████╔╝ ██║███████╗╚███╔███╔╝
╚═╝  ╚═╝╚══════╝  ╚═══╝  ╚═╝╚══════╝ ╚══╝╚══╝
```

# codereview.nvim

## Review pull requests and merge requests without leaving Neovim

![AI Review Demo](https://github.com/afewyards/codereview.nvim/releases/latest/download/ai-review.gif)

> **Note: This project is in active development.** Core features are operational, but some areas are still being refined. Please report issues or unexpected behavior via [GitHub Issues](https://github.com/afewyards/codereview.nvim/issues).

## Features

- **GitHub + GitLab** — auto-detects provider from git remote
- **Dual-pane diff viewer** — sidebar file tree + unified diff with inline comments
- **Threaded discussions** — view, reply, edit, delete, and resolve/unresolve comment threads
- **Note selection** — cycle through notes in a thread with `<Tab>`/`<S-Tab>`, then edit or delete inline
- **AI-powered review** — multi-provider support (Claude CLI, Anthropic API, OpenAI, Ollama, custom) with accept/dismiss/edit suggestions
- **AI comment solving** — press `sc` to auto-fix a review comment: generates a unified diff, applies it via `git apply`, and offers a commit message; `sf` / `sC` solve all comments in the current file or the entire PR
- **Copy & pipe comments** — `yc` copies a comment to the clipboard; `ya` pipes it to an AI tool via the `hooks.pipe_comment` callback (e.g., sidekick.nvim)
- **Open file in editor** — `<leader>gf` opens the current file in a vsplit alongside the diff, jumping to the commented line
- **Review sessions** — accumulate draft comments, submit in batch
- **MR actions** — approve, merge, open in browser, create new MR/PR

![Create MR/PR](https://github.com/afewyards/codereview.nvim/releases/latest/download/open-mr.gif)

- **Pipeline view** — monitor CI/CD status, view job logs, retry failed jobs

![Pipeline View](https://github.com/afewyards/codereview.nvim/releases/latest/download/pipeline.gif)

- **Picker integration** — Telescope, FZF, or Snacks
- **Fully remappable keybindings** — override or disable any binding

## Installation

### lazy.nvim

```lua
---@module "lazy"
---@type LazySpec
{
  "afewyards/codereview.nvim",
  dependencies = { "nvim-lua/plenary.nvim" },
  cmd = {
    "CodeReview",
    "CodeReviewAI",
    "CodeReviewAIFile",
    "CodeReviewStart",
    "CodeReviewSubmit",
    "CodeReviewApprove",
    "CodeReviewOpen",
    "CodeReviewPipeline",
    "CodeReviewComments",
    "CodeReviewFiles",
    "CodeReviewToggleScroll",
    "CodeReviewCommits",
    "CodeReviewSolveFile",
    "CodeReviewSolveAll",
  },
  ---@module "codereview"
  ---@type codereview.Config
  opts = {},
}
```

### packer.nvim

```lua
use {
  "afewyards/codereview.nvim",
  requires = { "nvim-lua/plenary.nvim" },
  config = function()
    require("codereview").setup()
  end,
}
```

## Quick Start

```vim
:CodeReview
```

Opens a picker with open PRs/MRs. Select one to enter the review view with a file sidebar and diff viewer.

## Project Configuration

Create a `.codereview.nvim` file in your project root to set per-project defaults:

```ini
# codereview.nvim project config
platform = github
project = afewyards/codereview.nvim
base_url = https://api.github.com
token = ghp_xxxxxxxxxxxx
```

Lines starting with `#` are comments. Keys and values are trimmed of whitespace.

| Key | Description |
|-----|-------------|
| `platform` | `github` or `gitlab` (auto-detected from git remote if omitted) |
| `project` | `owner/repo` (auto-detected from git remote if omitted) |
| `base_url` | API URL override (e.g., self-hosted GitLab instance) |
| `token` | Auth token for this project |
| `ai_skip_patterns` | Comma-separated glob patterns — files matching any pattern are excluded from AI review |

> **Security:** Add `.codereview.nvim` to your `.gitignore` if it contains a token.

## Authentication

Token resolution order (first match wins):

1. Environment variable — `GITHUB_TOKEN` or `GITLAB_TOKEN`
2. Project config — `token` key in `.codereview.nvim`
3. Plugin setup — `github_token` or `gitlab_token` in `setup()`

## Plugin Configuration

```lua
require("codereview").setup({
  -- Provider settings (all auto-detected from git remote)
  base_url = nil,       -- API base URL override (e.g. "https://gitlab.example.com")
  project  = nil,       -- "owner/repo" override
  platform = nil,       -- "github" | "gitlab" | nil (auto-detect)
  github_token = nil,   -- GitHub personal access token
  gitlab_token = nil,   -- GitLab personal access token

  -- Picker: "telescope", "fzf", or "snacks" (auto-detected)
  picker = nil,

  -- Debug logging to .codereview.log
  debug = false,

  -- Open review in a new tab (set false to use current window)
  open_in_tab = true,

  -- Lifecycle hooks
  hooks = {
    -- Called when the user presses `ya` (pipe comment to AI).
    -- Receives { body, author, file, line } for the comment under the cursor.
    -- If nil, the comment is copied to the clipboard instead.
    pipe_comment = nil, -- fun(data: {body: string, author: string, file: string, line: integer|nil})
  },

  -- Diff viewer
  diff = {
    context          = 8,     -- lines of context (0-20)
    scroll_threshold = 50,    -- use scroll mode when file count <= threshold
    comment_width    = 80,    -- comment float width
    separator_char   = "╳",   -- hunk separator character
    separator_lines  = 3,     -- lines in hunk separator
  },

  -- Pipeline
  pipeline = {
    poll_interval = 10000,  -- status poll interval (ms)
    log_max_lines = 5000,   -- max lines in job log viewer
  },

  -- AI review
  ai = {
    enabled       = true,
    provider      = "claude_cli",  -- "claude_cli" | "codex_cli" | "copilot_cli" | "gemini_cli" | "opencode_cli" | "qwen_cli" | "anthropic" | "openai" | "ollama" | "custom_cmd"
    review_level  = "info",        -- "info" | "suggestion" | "warning" | "error"
    max_file_size = 500,           -- skip files larger than N lines (0 = unlimited)

    claude_cli = { cmd = "claude", model = nil, agent = "code-review" },
    codex_cli = { cmd = "codex", model = nil },
    copilot_cli = { cmd = "copilot", model = nil, agent = nil },
    gemini_cli = { cmd = "gemini", model = nil },
    opencode_cli = { cmd = "opencode", model = nil, agent = "plan", variant = nil },
    qwen_cli = { cmd = "qwen", model = nil },
    anthropic  = { api_key = nil, model = "claude-sonnet-4-20250514" },
    openai     = { api_key = nil, model = "gpt-4o", base_url = nil },
    ollama     = { model = "llama3", base_url = "http://localhost:11434" },
    custom_cmd = { cmd = nil, args = {} },
  },

  -- Override or disable keybindings
  keymaps = {
    -- quit = "q",              -- remap quit to q
    -- toggle_resolve = false,  -- disable toggle resolve
  },
})
```

### Hooks

Hooks let you integrate codereview.nvim with other Neovim plugins. Configure them in the `hooks` table inside `setup()`.

#### `hooks.pipe_comment`

Called when the user presses `ya` (pipe comment to AI). Receives a table with the comment's body, author, file path, and line number. If not configured, `ya` falls back to copying the comment to the clipboard.

```lua
require("codereview").setup({
  hooks = {
    pipe_comment = function(data)
      -- data: { body: string, author: string, file: string, line: integer|nil }
      -- Example: forward to sidekick.nvim
      require("sidekick").send(string.format("[%s:%s]\n%s", data.file, tostring(data.line or "?"), data.body))
    end,
  },
})
```

### AI Providers

Set `ai.provider` to choose a backend. Each provider has its own sub-table:

| Provider | Config key | Requirements |
|----------|-----------|--------------|
| Claude CLI | `claude_cli` | [Claude CLI](https://docs.anthropic.com/en/docs/claude-code) installed |
| Codex CLI | `codex_cli` | [Codex CLI](https://github.com/openai/codex) installed and authenticated |
| Copilot CLI | `copilot_cli` | [Copilot CLI](https://docs.github.com/en/copilot/concepts/agents/copilot-cli/about-copilot-cli) installed and authenticated |
| Gemini CLI | `gemini_cli` | [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and authenticated |
| OpenCode CLI | `opencode_cli` | [OpenCode CLI](https://github.com/anomalyco/opencode) installed and authenticated |
| Qwen CLI | `qwen_cli` | [Qwen CLI](https://github.com/QwenLM/qwen-code) installed and authenticated |
| Anthropic API | `anthropic` | `api_key` set |
| OpenAI | `openai` | `api_key` set |
| Ollama | `ollama` | Ollama running locally |
| Custom command | `custom_cmd` | `cmd` set |

**Example — Anthropic API:**
```lua
ai = {
  provider = "anthropic",
  anthropic = { api_key = vim.env.ANTHROPIC_API_KEY, model = "claude-sonnet-4-20250514" },
},
```

**Example — Ollama (local):**
```lua
ai = {
  provider = "ollama",
  ollama = { model = "llama3", base_url = "http://localhost:11434" },
},
```

### AI Review Level

The `ai.review_level` option controls the verbosity of AI code reviews. Higher levels filter out lower-severity comments:

| Level | Shows |
|-------|-------|
| `"info"` | Everything (default) |
| `"suggestion"` | Suggestions, warnings, and errors |
| `"warning"` | Warnings and errors only |
| `"error"` | Errors only |

The AI is instructed to skip items below the configured level, saving tokens and reducing noise. To see lower-severity items again, change the level and re-run the AI review.

### AI Skip Patterns

Skip specific files from AI review by adding patterns to `.codereview.nvim`:

```
ai_skip_patterns=*.test.ts,docs/**,*.snap,fixtures/**
```

Patterns are comma-separated globs, merged with plugin config `ai.skip_patterns` and built-in defaults (lockfiles, minified files, generated code, vendor directories).

## Default Keymaps

### Navigation

| Key | Action |
|-----|--------|
| `]f` / `[f` | Next / previous file |
| `]c` / `[c` | Next / previous commit |
| `j` / `k` | Move down / up (comment-aware) |
| `<Tab>` / `<S-Tab>` | Next / previous note in thread |

### Comments & Discussions

| Key | Action |
|-----|--------|
| `cc` | New comment (normal mode) |
| `cc` | Range comment (visual mode) |
| `r` | Reply to thread |
| `e` | Edit selected note |
| `x` | Delete selected note |
| `rr` | React to note |
| `R` | Toggle resolve / unresolve |
| `yc` | Copy comment to clipboard |
| `ya` | Pipe comment to AI (calls `hooks.pipe_comment`; falls back to clipboard) |
| `sc` | Solve comment with AI (generates & applies a fix, offers commit message) |
| `sf` | Solve all comments in current file with AI |
| `sC` | Solve all PR/MR comments with AI |

### AI Suggestions

| Key | Action |
|-----|--------|
| `A` | Start / cancel AI review |
| `af` | AI review current file |
| `a` | Accept suggestion |
| `x` | Dismiss suggestion |
| `e` | Edit suggestion |
| `ds` | Dismiss all suggestions |

### View Controls

| Key | Action |
|-----|--------|
| `<C-f>` | Toggle full file view |
| `<leader>gf` | Open file in editor (vsplit alongside diff, at the cursor line) |

### Actions

| Key | Action |
|-----|--------|
| `<C-s>` | Submit draft comments |
| `<C-a>` | Approve MR/PR |
| `<C-r>` | Refresh |
| `<C-q>` | Quit |
| `M` | Merge |
| `o` | Open in browser |
| `p` | Show pipeline status |

### Picker

| Key | Action |
|-----|--------|
| `<leader>fc` | Browse comments / suggestions |
| `<leader>ff` | Browse changed files |
| `C` | Browse commits |

### Customizing Keymaps

Every keybinding can be remapped to a different key or disabled entirely via the `keymaps` option:

```lua
keymaps = {
  quit = "q",              -- remap quit from <C-q> to q
  toggle_resolve = false,  -- disable toggle resolve
  ai_review = "<leader>ar", -- remap AI review
},
```

Available action names: `next_file`, `prev_file`, `next_commit`, `prev_commit`, `move_down`, `move_up`, `select_next_note`, `select_prev_note`, `create_comment`, `create_range_comment`, `accept_suggestion`, `dismiss_suggestion`, `edit_suggestion`, `reply`, `edit_note`, `delete_note`, `react`, `toggle_resolve`, `toggle_full_file`, `dismiss_all_suggestions`, `submit`, `approve`, `refresh`, `quit`, `open_in_browser`, `merge`, `show_pipeline`, `ai_review`, `ai_review_file`, `pick_comments`, `pick_files`, `pick_commits`, `copy_comment`, `pipe_comment`, `solve_comment`, `solve_file_comments`, `solve_all_comments`, `open_file`.

## Commands

| Command | Description |
|---------|-------------|
| `:CodeReview` | Open review picker |
| `:CodeReviewAI` | Run AI review on entire diff |
| `:CodeReviewAIFile` | Run AI review on current file |
| `:CodeReviewStart` | Start manual review session (comments become drafts) |
| `:CodeReviewSubmit` | Submit draft comments |
| `:CodeReviewApprove` | Approve current MR/PR |
| `:CodeReviewOpen` | Create new MR/PR |
| `:CodeReviewPipeline` | Show pipeline status |
| `:CodeReviewComments` | Browse comments and suggestions |
| `:CodeReviewFiles` | Browse changed files |
| `:CodeReviewToggleScroll` | Toggle scroll / per-file mode |
| `:CodeReviewCommits` | Browse commits |
| `:CodeReviewSolveFile` | Solve all open comments in the current file with AI |
| `:CodeReviewSolveAll` | Solve all open PR/MR comments with AI |

## Supported Providers

| Provider | Reviews | Comments | Resolve | AI Review | Create MR/PR |
|----------|---------|----------|---------|-----------|-------------|
| GitLab | Yes | Yes | Yes | Yes | Yes |
| GitHub | Yes | Yes | Yes | Yes | Yes |

Provider is auto-detected from the git remote URL. Use `platform = "github"` or `platform = "gitlab"` to override.

## License

MIT
