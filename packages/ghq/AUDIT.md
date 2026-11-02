# ghq: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 1.11.2-1 (2026-11-03)

- **Why depot ships it:** factory's shared tool list has ghq; Arch ships it,
  Debian 13 and Fedora 44 do not.
- **Source:** upstream tag tarball
  `https://github.com/x-motemen/ghq/archive/refs/tags/v1.11.2.tar.gz`,
  sha256 `96b6bcb03976bf2dcec3630e654dc1519a126e9b4901e18c3489ceee69d49a58`.
  The `x-motemen` organization is the original author's.
- **Starting recipe:** written for depot (the AUR `ghq` is from 2024 and
  runs `go get`). Upstream's Makefile is a plain `go build` with `-X
  main.revision`.
- **Build:** `go build -trimpath -mod=readonly` with `GOTOOLCHAIN=local`, so
  Go never downloads a toolchain; modules come from proxy.golang.org, pinned
  by upstream's `go.sum`. Debian builds with `golang-1.26-go` from
  trixie-backports; the binary is static.
- **Upstream code read:** No `go:generate`, no build scripts. At run time
  ghq runs `git` (or other VCS) to clone; 22 modules.
- **Install:** no install script, no units, nothing outside `/usr/bin/ghq`
  and its docs. `check_package` enforces this on the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
