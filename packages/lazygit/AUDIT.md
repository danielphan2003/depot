# lazygit: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.66.2-1 (2026-11-03)

- **Why depot ships it:** factory's shared tool list has lazygit; Arch and
  Debian 13 ship it, Fedora 44 does not.
- **Source:** upstream tag tarball
  `https://github.com/jesseduffield/lazygit/archive/refs/tags/v0.66.2.tar.gz`,
  sha256 `fcaad0909af765ef87bd873164a4de78435515ab4d8b04f58d6ad51e8ecd00e5`.
  The author's own repository.
- **Starting recipe:** written for depot, after upstream's `.goreleaser.yml`
  (`-X main.version`, `main.buildSource`).
- **Build:** `go build -mod=vendor -trimpath` with `GOTOOLCHAIN=local`:
  upstream commits its dependencies in `vendor/`, which the go command
  checks against `vendor/modules.txt` and `go.mod`. No downloads. 70
  modules.
- **Upstream code read:** The `go:generate` lines are all inside `vendor/`
  and are not run. At run time lazygit runs `git`.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/lazygit` and its docs. `check_package` enforces this on the
  built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
