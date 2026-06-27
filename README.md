# iterm-mdpreview.nvim

Render `:MarkdownPreview` inside an iTerm2 browser split instead of a system browser window. Built on top of [`iamcco/markdown-preview.nvim`](https://github.com/iamcco/markdown-preview.nvim).

> Status: **alpha (v0.1)**. macOS + iTerm2 3.5+ only.

<!-- Add a short GIF here before tagging v0.1.0 (recommended: vhs or asciinema → mp4 → gif). -->

---

## Why

The default `:MarkdownPreview` flow throws a Safari/Chrome window onto your desktop, breaking the "everything inside the terminal" flow. This plugin hijacks mkdp's preview hand-off and opens the live preview in a right-side iTerm browser pane so:

- Focus stays in Neovim — no app switch, no window juggling.
- The preview moves with your iTerm window (Space, full-screen, tiling).
- `:MarkdownPreviewStop` and closing the markdown buffer both close the pane automatically.

---

## Requirements

| | |
|---|---|
| OS | macOS 13+ |
| iTerm2 | **3.5.0+** (Browser session support) |
| Neovim | 0.10+ |
| Dependency | [`iamcco/markdown-preview.nvim`](https://github.com/iamcco/markdown-preview.nvim) |
| Permissions | macOS Automation: Neovim/Terminal → iTerm (granted on first run) |

---

## Installation

### lazy.nvim

```lua
{
  "<your-github>/iterm-mdpreview.nvim",
  dependencies = {
    { "iamcco/markdown-preview.nvim", build = "cd app && npm install" },
  },
  ft = "markdown",
  opts = {},  -- defaults work out of the box once the iTerm profile exists
}
```

### packer.nvim

```lua
use {
  "<your-github>/iterm-mdpreview.nvim",
  requires = { { "iamcco/markdown-preview.nvim", run = "cd app && npm install" } },
  config = function() require("iterm-mdpreview").setup() end,
}
```

### vim-plug

```vim
Plug 'iamcco/markdown-preview.nvim', { 'do': 'cd app && npm install' }
Plug '<your-github>/iterm-mdpreview.nvim'

" then in init.lua / after-plug block:
lua require('iterm-mdpreview').setup()
```

---

## One-time iTerm profile setup

The plugin opens the preview in an iTerm **Browser-type** profile. Create one:

1. iTerm → Settings → Profiles → **+** (new profile)
2. Set **Profile Type** to **Browser** (iTerm 3.5+)
3. Leave the name as **`Browser`** — iTerm's default, and what this plugin expects.
   *(If you rename it, pass `profile = "<your name>"` to `setup()`.)*
4. Under **General → Custom URL**, set `file:///tmp/iterm-mdpreview.html`.
   This is the bridge file the plugin writes a meta-refresh into; the profile loading it is how the preview URL actually reaches the pane.
5. Run `:checkhealth iterm-mdpreview` to confirm everything is wired.

First `:MarkdownPreview` will trigger a macOS Automation permission prompt — allow Neovim (or your terminal host) to control iTerm.

---

## Configuration

```lua
require("iterm-mdpreview").setup({
  port = "8089",                              -- mkdp HTTP server port
  split = {
    direction = "right",                      -- right | left | below | above
    size = nil,                               -- percent (1-100); nil = iTerm default
  },
  auto_close = true,                          -- close split on BufWipeout/BufUnload
  reuse_split = false,                        -- v0.1: always opens a new split
  notify_level = vim.log.levels.INFO,
  iterm_app = "iTerm",                        -- AppleScript application name
  profile = "Browser",                        -- iTerm Browser-type profile name
  filetypes = { "markdown" },                 -- passed to mkdp_filetypes
  bridge_html = "/tmp/iterm-mdpreview.html",  -- where meta-refresh is written
  custom_script = nil,                        -- function(url) -> AppleScript (escape hatch)
})
```

---

## Commands

| Command | What it does |
|---|---|
| `:MarkdownPreview` | Upstream mkdp command; preview routes into the iTerm split via our `browserfunc` |
| `:MarkdownPreviewStop` | Overridden by this plugin: closes the iTerm split *and* stops mkdp's server |
| `:ItermMdPreview` | Alias for `:MarkdownPreview` |
| `:ItermMdPreviewStop` | Alias for `:MarkdownPreviewStop` |
| `:checkhealth iterm-mdpreview` | Diagnose platform, iTerm version, automation permission, mkdp presence |

---

## How it works

```
:MarkdownPreview
  └─► mkdp starts HTTP server on :8089
        └─► mkdp calls g:mkdp_browserfunc (= ItermMdpreviewBrowserFunc)
              └─► Lua: iterm.open_split(url)
                    └─► osascript scripts/open_split.applescript
                          ├─► writes meta-refresh HTML to bridge_html
                          ├─► tells iTerm to split with the Browser profile,
                          │   which loads bridge_html and is redirected to <url>
                          └─► returns session id → stored in Lua state

:MarkdownPreviewStop
  └─► overridden buffer-local command → Lua: stop()
        ├─► iterm.close_split(state.session_id)  -- osascript closes the pane
        └─► mkdp#util#stop_preview()             -- shuts the mkdp server
```

---

## Troubleshooting

**`osascript exited 1: Not authorized to send Apple events to iTerm.`**
First run triggers a macOS Automation prompt; if you missed or denied it, re-grant via *System Settings → Privacy & Security → Automation*, then enable Neovim (or your terminal host) → iTerm.

**Split opens but pane is empty / shows `iterm2-about:error`**
Either the profile is not a Browser-type, or its Custom URL doesn't match `bridge_html` (default `/tmp/iterm-mdpreview.html`). Double-check both.

**`:MarkdownPreviewStop` stops the server but the split stays open**
You probably installed an older version of this plugin (pre-buffer-local override). Update to v0.1.0+; mkdp creates a *buffer-local* `:MarkdownPreviewStop`, which only our buffer-local override can beat.

**`Can't connect to server` in the browser pane**
mkdp's HTTP server isn't running, or it bound to a non-loopback address. Check with `lsof -i :8089`. If empty, re-run mkdp's build step (`cd app && npm install` inside `markdown-preview.nvim`).

**Port 8089 in use**
`setup({ port = "8090" })` — port is forwarded to `g:mkdp_port`.

---

## Architecture invariants

Two non-obvious decisions inside the codebase that future contributors should keep:

1. **`scripts/*.applescript` wraps iTerm calls in `using terms from application "iTerm"`.** AppleScript only loads an app's scripting dictionary at *compile time* if the app name in `tell application "..."` is a string literal. Because we pass `iterm_app` as a parameter (variable), the dictionary won't load without `using terms from`, and any iTerm-specific verb (`split vertically`, `with profile`, `create window`) blows up with `(-2741) Expected end of line but found class name`.

2. **`:MarkdownPreviewStop` is overridden as a buffer-local command, not a global one.** mkdp registers its `:MarkdownPreviewStop` with `command! -buffer` on every markdown buffer; buffer-local commands shadow global ones, so a global `nvim_create_user_command` override silently loses. The plugin uses `nvim_buf_create_user_command` on every markdown buffer (via `FileType`/`BufEnter` autocmds plus a `vim.schedule` deferral so it runs *after* mkdp's handler in the same event chain).

If you simplify either of these, run the manual QA matrix in [CONTRIBUTING.md](./CONTRIBUTING.md) before merging — these regressions are silent until exercised.

---

## Roadmap

- [ ] `reuse_split = true`: navigate the existing pane instead of opening a new one
- [ ] Ship an importable iTerm `.json` profile so step "one-time setup" becomes a single click
- [ ] Health check actually performs a `split + close` round-trip
- [ ] Optional iTerm2 Python API backend for finer control

---

## Credits

- [iamcco/markdown-preview.nvim](https://github.com/iamcco/markdown-preview.nvim) — handles all the rendering and live reload heavy lifting.
- iTerm2's [browser session support](https://iterm2.com/) in 3.5+ — the reason this plugin can exist.

## License

MIT. See [LICENSE](./LICENSE).
