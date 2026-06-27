## Summary

<!-- What does this PR change and why? Link issues if relevant. -->

## Manual QA

If this PR touches AppleScript, command registration, or the open/close lifecycle, run the matrix in CONTRIBUTING.md and check the boxes:

- [ ] `:MarkdownPreview` opens the iTerm Browser split
- [ ] `:MarkdownPreviewStop` closes the split **and** stops mkdp's server
- [ ] `:verbose command MarkdownPreviewStop` shows our buffer-local override winning
- [ ] `:checkhealth iterm-mdpreview` is green
- [ ] Tested on iTerm version: ______ / Neovim version: ______

## Checklist

- [ ] `make check` passes
- [ ] `make test` passes
- [ ] CHANGELOG entry under `[Unreleased]`
- [ ] Architecture invariants in CONTRIBUTING.md respected (AppleScript `using terms from`, buffer-local command override)
