# Changelog

All notable changes are documented here. Format follows [Keep a Changelog](https://keepachangelog.com/); versions follow [SemVer](https://semver.org/).

## [Unreleased]

## [0.1.0] — initial alpha

### Added
- `setup()` API with validated configuration (port, split direction/size, profile, auto_close, bridge_html, custom_script).
- AppleScript-backed split-and-load flow (`scripts/open_split.applescript`) replacing the previous keystroke-simulation hack.
- Session tracking + `scripts/close_split.applescript` for clean teardown.
- `:ItermMdPreview` / `:ItermMdPreviewStop` user commands.
- Override of upstream `:MarkdownPreviewStop` (buffer-local + global) so closing the preview also closes the iTerm split.
- `:checkhealth iterm-mdpreview` covering platform, iTerm version, automation permission, mkdp presence.
- vim help (`:help iterm-mdpreview`).

### Implementation notes

These two patterns are load-bearing; do not refactor them away without re-running the manual QA matrix:

- AppleScript wrappers use `using terms from application "iTerm"` so the iTerm dictionary loads at compile time even though the app name is passed as a runtime variable. Without it, iTerm-specific verbs (`split vertically`, `with profile`, `create window`) fail with error -2741.
- `:MarkdownPreviewStop` is overridden as a **buffer-local** command via `nvim_buf_create_user_command`. mkdp installs its own buffer-local version that shadows any global override; the plugin re-installs ours via a `FileType`/`BufEnter` autocmd with `vim.schedule` deferral so we run last in the same event chain.

### Known limitations
- `reuse_split` not yet implemented (always opens a new split).
- iTerm Browser profile must be created manually; no JSON shipped yet.
- iTerm AppleScript dictionary does not expose direct URL navigation on Browser sessions, so the URL is delivered via a meta-refresh HTML bridge file that the profile's Custom URL points at.
- No automated integration tests against iTerm (manual QA matrix only).
