# flyctl: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.5.2-1 (2026-11-03)

- **Why depot ships it:** Fly.io's CLI; Daniel keeps it although `firefly`
  was retired. Replaces the AUR's `flyctl-bin`.
- **Source:** upstream tag tarball
  `https://github.com/superfly/flyctl/archive/refs/tags/v0.5.2.tar.gz`,
  sha256 `7655f0fdc81a5c09c26c22a2d1786bbaa4470d0b7385d4683a9df8795a47bbb5`.
  Fly.io's own repository.
- **Starting recipe:** AUR `flyctl` (aur.git `a21cf43`): `make build` (which
  runs `go generate ./...`) pinned by b2sum, and `make test`. depot follows
  upstream's `.goreleaser.yml`: `go generate ./...`, then a static build
  with the `production` tag and the version in ldflags. `make test` is
  dropped: its tests need Fly's API and Docker.
- **Build:** `go build -trimpath -mod=readonly` with `GOTOOLCHAIN=local`, so
  Go never downloads a toolchain; modules come from proxy.golang.org, pinned
  by upstream's `go.sum`. `go generate` runs `genqlient` against the bundled
  `gql/schema.graphql` and `mockgen` for one test package, both pinned in
  `go.mod`.
- **Upstream code read:** Talks to Fly.io's API and sends Fly's usage
  metrics, as the upstream binary does. Self-update:
  `CanUpdateThisInstallation()` is true only for a binary under `~/.fly`, so
  a copy in `/usr/bin` never runs Fly's `curl | sh` installer; it may print
  an upgrade hint, which `FLY_NO_UPDATE_CHECK=1` silences. `deps/wintun`
  holds Windows DLLs, used only on Windows. The AUR's `/usr/bin/fly` symlink
  is a two-line `exec /usr/bin/flyctl "$@"` script, since depot packages
  carry no links.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/flyctl`, `/usr/bin/fly`, its README and license. `check_package`
  enforces this on the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
