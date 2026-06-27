# Contributing

Thanks for considering a contribution.

## Dev setup

```
git clone https://github.com/<your-github>/iterm-mdpreview.nvim
cd iterm-mdpreview.nvim
```

Optional tooling:

- `stylua` — formatting (`make fmt`)
- `luacheck` — linting (`make check`)
- `plenary.nvim` — unit tests (`make test`)

## Architecture invariants (read before changing AppleScript or command registration)

Two non-obvious patterns are load-bearing; they exist because of bugs that took rounds of debugging to find. Don't simplify them away without re-running the full manual QA matrix.

### 1. AppleScript files wrap iTerm calls in `using terms from application "iTerm"`

AppleScript loads an app's scripting dictionary at *compile time*, but only when the app name in `tell application "..."` is a string literal. Because we pass `iterm_app` as a runtime parameter (`tell application itermApp`), the dictionary won't load without `using terms from`, and iTerm-specific verbs (`split vertically`, `with profile`, `create window`) blow up with error `(-2741) Expected end of line but found class name`. The `try` block does not catch this — it's a compile error, not runtime.

### 2. `:MarkdownPreviewStop` is overridden as buffer-local, not global

mkdp registers its own `:MarkdownPreviewStop` with `command! -buffer` on every markdown buffer (visible via `:verbose command MarkdownPreviewStop` — note the `b` prefix). Buffer-local commands shadow global ones, so a global `nvim_create_user_command` override silently loses on markdown buffers. The plugin's override has to use `nvim_buf_create_user_command` on each markdown buffer, *and* must be installed after mkdp's autocmd in the same event chain — so we wrap our `FileType` / `BufEnter` handler in `vim.schedule(...)` to defer one tick.

A global fallback override is kept too, for the rare case where `:MarkdownPreviewStop` is invoked from a non-markdown buffer.

## Manual QA matrix (run before tagging a release)

```
[ ] :MarkdownPreview on a fresh nvim → right-side iTerm Browser pane appears
[ ] Edit the markdown buffer → preview updates live
[ ] :MarkdownPreviewStop → BOTH the iTerm pane closes AND mkdp server stops
[ ] :verbose command MarkdownPreviewStop in a markdown buffer →
    the buffer-local definition points to our init.lua, not mkdp.vim
[ ] Close the markdown buffer (auto_close=true) → pane closes automatically
[ ] Open a second markdown buffer after first preview → behavior matches
    reuse_split setting (false: new pane each time)
[ ] iTerm not running at start → plugin launches it and works
[ ] mkdp port already in use → friendly notify, no traceback
[ ] iTerm 3.4 (no Browser session) → split opens but is empty;
    error is actionable (not a stack trace)
[ ] Automation permission revoked → :checkhealth flags it; preview prints
    a clear error pointing at System Settings
```

## Reporting bugs

Open an issue with:

- macOS version
- iTerm2 version (iTerm → About iTerm2)
- Neovim version (`:version`)
- markdown-preview.nvim commit (`:Lazy show markdown-preview.nvim` or similar)
- Minimal repro steps
- Output of `:checkhealth iterm-mdpreview`
- Output of `:verbose command MarkdownPreviewStop` (if the bug is about stop behavior)

## PR checklist

- [ ] `make check` passes (`stylua --check`, `luacheck`)
- [ ] `make test` passes (busted via plenary)
- [ ] CHANGELOG entry under `[Unreleased]`
- [ ] Doc (`doc/`, README) updated if user-visible
- [ ] Manual QA matrix above run if touching AppleScript, command registration, or open/close paths
