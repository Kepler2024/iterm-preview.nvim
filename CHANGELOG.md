# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

## [Unreleased]

> Alpha config-surface changes: `split.size` and `reuse_split` were removed (see below). If you set
> either, drop it; they were no-ops or contradictory.

### Fixed
- `auto_close` now only tears down the preview when the *previewed* buffer is wiped/deleted, matched
  by buffer number. Previously, closing **any** markdown buffer killed an unrelated active preview.
- Switched the auto-close trigger from `BufUnload` to `BufWipeout`/`BufDelete`, so `:edit` reloads of
  the previewed file no longer close the preview.
- Re-previewing (e.g. opening a preview on a second markdown file) no longer orphans the first pane:
  the previous pane is always closed before a new one opens.
- `:ItermMdPreview` on a non-markdown buffer now prints an actionable message instead of a misleading
  "not installed" error.

### Changed
- **Focus stays in Neovim.** `open_split.applescript` now returns keyboard focus to the
  originally-active iTerm session after splitting, instead of leaving it in the new browser pane.
- The meta-refresh bridge file is written by Lua (with HTML escaping) rather than via a shell
  `printf` inside AppleScript; this removes a shell-injection surface and centralizes escaping. The
  AppleScript no longer receives the URL; it only performs the split.
- Config validation no longer uses the table form of `vim.validate` (soft-deprecated in Neovim 0.11+
  and slated for removal). Hand-rolled checks work on every supported version with no deprecation
  warnings.
- `:checkhealth iterm-preview` now: uses the configured `iterm_app`; reports the real
  `g:mkdp_port`; verifies the bridge directory is writable; prints the exact `file://…` Custom URL
  the profile needs; notes whether Neovim is running inside iTerm2; and shows the active preview.
- `open_split` waits up to 15s so the one-time macOS Automation permission prompt has time to be
  accepted on first run.
- Added unit tests for `state`; README rewritten.
- Docs now present `:ItermMdPreview` / `:ItermMdPreviewStop` as the primary commands, with
  `:MarkdownPreview` / `:MarkdownPreviewStop` documented as transparently rerouted aliases.

### Removed
- `split.size`: validated and documented but never applied (AppleScript can't set the split divider
  ratio). Planned to return via an iTerm2 Python API backend.
- `reuse_split`: superseded by the always-single-pane model; true in-pane navigation is on the
  roadmap.

## [0.1.0] - initial alpha

### Added
- `setup()` API with validated configuration (port, split direction/size, profile, auto_close, bridge_html, custom_script).
- AppleScript-backed split-and-load flow (`scripts/open_split.applescript`) replacing the previous keystroke-simulation hack.
- Session tracking + `scripts/close_split.applescript` for clean teardown.
- `:ItermMdPreview` / `:ItermMdPreviewStop` user commands.
- Override of upstream `:MarkdownPreviewStop` (buffer-local + global) so closing the preview also closes the iTerm split.
- `:checkhealth iterm-preview` covering platform, iTerm version, automation permission, mkdp presence.
- vim help (`:help iterm-preview`).

### Implementation notes

These two patterns are load-bearing; do not refactor them away without re-running the manual QA matrix:

- AppleScript wrappers use `using terms from application "iTerm"` so the iTerm dictionary loads at compile time even though the app name is passed as a runtime variable. Without it, iTerm-specific verbs (`split vertically`, `with profile`, `create window`) fail with error -2741.
- `:MarkdownPreviewStop` is overridden as a **buffer-local** command via `nvim_buf_create_user_command`. mkdp installs its own buffer-local version that shadows any global override; the plugin re-installs ours via a `FileType`/`BufEnter` autocmd with `vim.schedule` deferral so we run last in the same event chain.

### Known limitations
- `reuse_split` not yet implemented (always opens a new split).
- iTerm Browser profile must be created manually; no JSON shipped yet.
- iTerm AppleScript dictionary does not expose direct URL navigation on Browser sessions, so the URL is delivered via a meta-refresh HTML bridge file that the profile's Custom URL points at.
- No automated integration tests against iTerm (manual QA matrix only).
