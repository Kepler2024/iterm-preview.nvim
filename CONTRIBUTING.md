# Contributing

Thanks for considering a contribution.

## Dev setup

```
git clone https://github.com/<your-github>/iterm-preview.nvim
cd iterm-preview.nvim
```

Optional tooling:

- `stylua`: formatting (`make fmt`)
- `luacheck`: linting (`make check`)
- `plenary.nvim`: unit tests (`make test`)

## Architecture invariants (read before changing AppleScript or command registration)

Two non-obvious patterns are load-bearing; they exist because of bugs that took rounds of debugging to find. Don't simplify them away without re-running the full manual QA matrix.

### 1. AppleScript files wrap iTerm calls in `using terms from application "iTerm"`

AppleScript loads an app's scripting dictionary at *compile time*, but only when the app name in `tell application "..."` is a string literal. Because we pass `iterm_app` as a runtime parameter (`tell application itermApp`), the dictionary won't load without `using terms from`, and iTerm-specific verbs (`split vertically`, `with profile`, `create window`) blow up with error `(-2741) Expected end of line but found class name`. This is a *compile* error, so wrapping the call in a `try` would not catch it either.

Related: the meta-refresh bridge file is written in Lua (`iterm.lua` → `write_bridge`), **not** in AppleScript. The script no longer receives the URL or touches the shell; it only performs the split and hands back the new session id. Keep URL escaping on the Lua side.

### 2. `:MarkdownPreviewStop` is overridden as buffer-local, not global

mkdp registers its own `:MarkdownPreviewStop` with `command! -buffer` on every markdown buffer (visible via `:verbose command MarkdownPreviewStop`, note the `b` prefix). Buffer-local commands shadow global ones, so a global `nvim_create_user_command` override silently loses on markdown buffers. The plugin's override has to use `nvim_buf_create_user_command` on each markdown buffer, *and* must be installed after mkdp's autocmd in the same event chain, so we wrap our `FileType` / `BufEnter` handler in `vim.schedule(...)` to defer one tick.

A global fallback override is kept too, for the rare case where `:MarkdownPreviewStop` is invoked from a non-markdown buffer.

## Manual QA matrix (run before tagging a release)

```
[ ] :MarkdownPreview on a fresh nvim → right-side iTerm Browser pane appears
[ ] After :MarkdownPreview → keyboard focus is back in the Neovim pane,
    NOT in the new browser pane
[ ] Edit the markdown buffer → preview updates live
[ ] :MarkdownPreviewStop → BOTH the iTerm pane closes AND mkdp server stops
[ ] :verbose command MarkdownPreviewStop in a markdown buffer →
    the buffer-local definition points to our init.lua, not mkdp.vim
[ ] Close the previewed markdown buffer (auto_close=true) → pane closes
[ ] Close an UNRELATED markdown buffer while a preview is open →
    the preview pane stays open (regression guard for the bufnr match)
[ ] :edit (reload) the previewed buffer → preview survives
[ ] Open a preview on a second markdown file → the first pane closes,
    exactly one preview pane remains (single-preview model)
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
- Output of `:checkhealth iterm-preview`
- Output of `:verbose command MarkdownPreviewStop` (if the bug is about stop behavior)

## PR checklist

- [ ] `make check` passes (`stylua --check`, `luacheck`)
- [ ] `make test` passes (busted via plenary)
- [ ] CHANGELOG entry under `[Unreleased]`
- [ ] Doc (`doc/`, README) updated if user-visible
- [ ] Manual QA matrix above run if touching AppleScript, command registration, or open/close paths
