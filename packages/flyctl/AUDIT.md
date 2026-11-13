# flyctl: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.5.10-1 (2026-11-13)

- **Why depot ships it:** Fly.io's CLI; Daniel keeps it although `firefly`
  was retired. Replaces the AUR's `flyctl-bin`.
- **Source:** upstream tag archive
  `https://github.com/superfly/flyctl/archive/refs/tags/v0.5.10.tar.gz`,
  sha256 `71b5ab222980ac3d6d10e5f65a26af660d4ff3ac996fa6b918345ca515f4bc80`.
  The downloaded archive matches. Upstream's
  `flyctl_0.5.10_checksums.txt` lists release binaries, not this tag archive.
  The tag ref points directly to commit `1f836fe16302703423c9751e5ae24afacf17377f`
  (a lightweight tag, with no tag signature); GitHub reports that commit's
  signature as verified. GitHub's attestation lookup for the archive returns
  404. **Not sure:** no upstream checksum or build attestation covers the
  source archive, and the pinned hash is the recipe's only archive hash.
- **Build and dependencies:** the package builds from source with Go.
  `GOFLAGS=-mod=readonly` and `GOTOOLCHAIN=local` keep Go from changing the
  module graph or downloading its own toolchain; `go.sum` pins module contents.
  `go generate ./...` uses the bundled GraphQL schema and generators pinned in
  `go.mod`. The 0.5.2 to 0.5.8 update promoted existing indirect modules to
  direct requirements; the 0.5.8 to 0.5.10 diff adds no module changes.
- **Upstream code read:** the full diff `v0.5.2...v0.5.10` and the delta
  `v0.5.8...v0.5.10` (five commits). The earlier update's changes remain:
  custom private-network support, token-file synchronization, an explicit
  `fly feedback` command, per-app affinity tokens, and changes to automatic
  metrics. `fly feedback` is user-invoked and sends the note plus optional
  request ID or URL to Fly's API. `fly launch` can create a limited deploy
  token and pass it to `gh secret set FLY_API_TOKEN` when setting up a GitHub
  Actions deploy; failure now leaves instructions for doing that manually.
  - The new metrics include `login_method` and can be flushed after command
    cancellation. The sender now gets a metrics token with a short,
    cancellation-independent timeout, making those metrics more likely to be
    sent. **Not sure:** this expands automatic usage reporting and still needs
    Daniel's approval.
  - The 0.5.10 delta clarifies the `FlyV1` token prefix, lets
    `fly mpg connect` run SQL from command/file input, improves psql guidance,
    rejects unknown subcommands, and keeps `.git` out of generated build
    contexts. I found no new telemetry fields or network destination in this
    delta. The release workflow is unchanged; its Docker build images moved to
    Go 1.27.3. No new third-party module publisher was introduced.
- **Install:** no install script, units, or triggers. The recipe still installs
  `/usr/bin/flyctl`, the `fly` wrapper, README, and license; no new install path
  is needed.
- **Upstream status:** active, same owner (`superfly`), not archived; the
  release process is unchanged.
- **Audit decision:** held. The source archive has no upstream checksum or
  build attestation, and the expanded automatic metrics need Daniel's
  approval.
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
