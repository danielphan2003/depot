# flyctl: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.5.8-1 (2026-11-13)

- **Why depot ships it:** Fly.io's CLI; Daniel keeps it although `firefly`
  was retired. Replaces the AUR's `flyctl-bin`.
- **Source:** upstream tag tarball
  `https://github.com/superfly/flyctl/archive/refs/tags/v0.5.8.tar.gz`,
  sha256 `b3d9e10336568f861895f9e21c3085786f0cfecb758c7c9ccf74f68976a2645b`.
  The archive I downloaded has that hash. Upstream's
  `flyctl_0.5.8_checksums.txt` lists release binaries, not this tag tarball.
  The tag is unsigned and the GitHub attestation lookup for the tarball returns
  404. **Not sure:** no upstream checksum, signature, or attestation covers
  the source archive. Hold this update for Daniel.
- **Starting recipe:** unchanged from the AUR `flyctl` recipe
  (`aur.git` commit `a21cf43`). This PR updates the version and source hash.
- **Build and dependencies:** the package builds from source with Go. The
  recipe sets `GOFLAGS=-mod=readonly` and `GOTOOLCHAIN=local`; `go.sum` pins
  module contents. `go generate ./...` uses the bundled GraphQL schema and
  generators pinned by `go.mod`. The `go.mod` changes promote several existing
  indirect modules to direct requirements (`apex/log`, `containerd/api`,
  `go-containerregistry`, `mcp-go`, `fsutil`, and `google.golang.org/protobuf`).
  These were already in the prior module graph, so I found no new module
  publisher. Go builds with `CGO_ENABLED=0` and upstream's release flags.
- **Upstream code read:** I compared `v0.5.2...v0.5.8`. The diff fixes Fly's
  personal-organization tunnel identity and token-file synchronization, adds
  custom private-network support, and adds a `fly feedback` command. Feedback
  is an explicit user action that sends a note, optional request ID or URL,
  and the active account token to Fly's feedback API. The new affinity store
  writes short-lived per-app routing tokens under the config directory with
  mode `0600`, keyed by a hash of the endpoint and app name, and prunes expired
  files. The update also adds `login_method` to automatic command metrics and
  sends queued metrics after command cancellation. **Not sure:** this adds a
  telemetry field and makes metrics more likely to be sent; Daniel needs to
  approve that change. I found no new third-party network destination,
  obfuscated code, or vendored executable. The Docker build images update to
  Go 1.27.3; the release workflow is unchanged.
- **Install:** no install script, units, or triggers. The recipe still installs
  `/usr/bin/flyctl`, its `fly` wrapper, the README, and the license. No
  `allow` entry or new install path is needed.
- **Upstream status:** active and not archived, with the same owner,
  `superfly`. Release 0.5.8 was published on 2026-11-11; the release process
  is unchanged.
- **Reviewed by:** GPT-6 Luna for Daniel, 2026-11-13.

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
