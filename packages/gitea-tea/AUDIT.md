# gitea-tea: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.16.0-1 (2026-11-03)

- **Why depot ships it:** tea, the Gitea CLI, is in factory's shared tool
  list; Arch ships it as `tea`, Fedora 44 not at all, and Debian's `tea` is
  an unrelated Qt text editor. depot names the package `gitea-tea` so apt
  never confuses the two; the command is still `tea`.
- **Source:** the Go module proxy's zip of the v0.16.0 tag,
  `https://proxy.golang.org/gitea.dev/tea/@v/v0.16.0.zip`, sha256
  `148e88a80b8bf918d10596cd7d7577e88d67de7b1bea6beec5a113a208f58332`.
  gitea.com is where the Gitea project develops tea (the GitHub
  `go-gitea/tea` repository was archived in 2019), but it answers 403 to
  archive downloads from some GitHub runner addresses, which failed builds
  at random. The zip's tree is identical, file for file, to the audited
  upstream archive `https://gitea.com/gitea/tea/archive/v0.16.0.tar.gz`
  (sha256 `3c8523e551f576290c69fe6375208e0cb27d4fc1e48b29b13e02ca6ada851c05`),
  and its module hash, computed from the zip,
  `h1:N/jg+8UhYdKHF3rLlNRgQFFfHrZMcIKMbaZISjVccQk=`, is the one the Go
  checksum database records for `gitea.dev/tea@v0.16.0`, so the proxy
  cannot serve a different tree for this version. A bump keeps the same
  check: the proxy's zip, compared with the gitea.com archive of the tag.
- **Starting recipe:** written for depot, after Arch's official `tea`
  PKGBUILD and upstream's Makefile (`-X
  gitea.dev/tea/modules/version.Version` and `.SDK`).
- **Build:** `go build -trimpath -mod=readonly` with `GOTOOLCHAIN=local`, so
  Go never downloads a toolchain; modules come from proxy.golang.org, pinned
  by upstream's `go.sum`. Debian builds with `golang-1.26-go` from
  trixie-backports; the binary is static.
- **Upstream code read:** No `go:generate` in the build; `build.go` is a
  `//go:build ignore` helper for docs. Talks only to the Gitea servers it is
  logged in to. 89 modules.
- **Install:** no install script, no units, nothing outside `/usr/bin/tea`
  and its docs. `check_package` enforces this on the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
