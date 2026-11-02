# carapace: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 1.8.2-1 (2026-11-03)

- **Why depot ships it:** the completion engine Daniel's nushell
  configuration loads (`dotfiles/nushell/config.nu` in factory). Replaces
  the AUR's `carapace-bin`. Built for every target so the shared shell
  configuration works on each machine; no distribution ships it.
- **Source:** upstream tag tarball
  `https://github.com/carapace-sh/carapace-bin/archive/refs/tags/v1.8.2.tar.gz`,
  sha256 `56b934e1c94cb4e10d912c0158a74f8b727e430e6d9c8aff5bfb99e124fa3ace`
  (the same hash the AUR pins). The `carapace-sh` organization is the
  author's (rsteube) own.
- **Starting recipe:** AUR `carapace` (aur.git `db93fc6`): `go generate
  ./cmd/...`, then a static `go build` with tags `release,force_all`. depot
  follows upstream's `.goreleaser.yml` instead: the same generate step and
  the `release` tag only.
- **Build:** `go build -trimpath -mod=readonly` with `GOTOOLCHAIN=local`, so
  Go never downloads a toolchain; modules come from proxy.golang.org, pinned
  by upstream's `go.sum`. Two `replace` lines point `spf13/pflag` and
  `kevinburke/ssh_config` at the carapace organization's own forks, pinned
  in `go.sum`. Debian builds with `golang-1.26-go` from trixie-backports
  (trixie's Go is 1.24; go.mod asks for 1.26); the binary is static, so
  nothing from backports is needed at run time.
- **Upstream code read:** `go generate` runs `cmd/carapace-generate` from
  the same tarball. It scans the source tree's completers and the
  go.sum-pinned action packages and writes Go files; the only command it
  runs is `go mod edit -json`. No network beyond the module proxy. At run
  time carapace executes the commands it completes for (e.g. `git` to list
  branches), as any completer does.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/carapace`, its README and license. `check_package` enforces this
  on the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
