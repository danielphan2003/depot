# flyctl: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.5.15-1 (2026-11-23)

- **Change:** upstream's 0.5.15, one release on from 0.5.14. The recipe is
  unchanged apart from the version and the source hash.
- **Source:** upstream tag tarball
  `https://github.com/superfly/flyctl/archive/refs/tags/v0.5.15.tar.gz`,
  sha256 `f1906b8203d1d9ed8e78f974978f42f109f12adaaef9f05bf8486afa04dfbbbe`.
  The archive I downloaded has that hash. Upstream's
  `flyctl_0.5.15_checksums.txt` lists the release binaries, not this tag
  tarball, and the tag is lightweight (it points straight at commit
  `bcead3a580e7b61e00b7046aa512558adbb94e9b`, authored by tripledoublev and
  reported by GitHub as verified). GitHub's attestation lookup for the
  archive answers 404, as it did for 0.5.10 and 0.5.14. So I checked the
  archive against the tag commit's tree instead: all 1135 files it holds are
  byte-identical (same blob hash, no extra or missing file) to that commit's
  tree, so the tarball is exactly the tag's tree as GitHub generated it from
  `superfly/flyctl`.
- **Build and dependencies:** unchanged. Go from source with
  `GOFLAGS=-mod=readonly`, `GOTOOLCHAIN=local`, `CGO_ENABLED=0` and upstream's
  `production` tag and ldflags; makepkg supplies the distribution's flags.
  `go generate ./...` runs genqlient against the bundled `gql/schema.graphql`
  and mockgen, both pinned in `go.mod`. `go.mod` and `go.sum` only bump
  modules that were already pinned, all from publishers already trusted:
  `superfly/fly-go` 0.12.1 to 0.12.7, `mark3labs/mcp-go` 1.5.0,
  `depot/depot-go` 0.5.4, `containerd/containerd/v2` 2.4.2 and the
  `golang.org/x/*` set. `opencontainers/go-digest` moves from indirect to
  direct at the same v1.0.0. No module path is new, so no new dependency
  publisher. The `Makefile`, `.goreleaser.yml` and `Dockerfile` are
  untouched; the only workflow change is `docker/login-action` 4.7.0 to
  4.8.0.
- **Upstream code read:** I compared `v0.5.14...v0.5.15`, 22 commits and 71
  files, reading the patches rather than the changelog.
  - `deploy` now releases partially acquired Machine leases when a deploy
    fails, instead of leaving them held. The secret warning that used to fire
    on any value containing `KEY`, `PRIVATE`, `DATABASE_URL`, `PASSWORD` or
    `SECRET` now keys off the variable name only, with an allowlist, and a
    `DATABASE_URL` pointing at a plain local SQLite file no longer warns; the
    new pattern refuses authorities, URI options and escaped characters so
    only simple filenames match.
  - `internal/build/imgsrc` gains recovery for a pushed image when the local
    daemon no longer has it: `inspectPushedTag` asks the daemon that pushed
    the image to inspect the live tag with Fly's registry auth
    (`flyRegistryAuth(config.Tokens(ctx).Docker())`, the existing token
    plumbing, no new endpoint), compares the digest with the one that was
    pushed, and only then resolves the pinned manifest through Fly's API. The
    wait helpers were generalized (`waitForImage`) without changing their
    timeouts or backoff. Buildpacks and nixpacks builders use the same path,
    and one Machine is now used for the image-label preflight.
  - `machine start` waits for a newly created Machine to finish starting,
    reports the start conflict with the Machine that holds the lease, and
    `machine status` shows the rootfs size. Process groups without services
    are created as one Machine.
  - `mpg create` allows Postgres 18 and defaults to 17; `mpg attach` reads a
    v2 cluster's credentials from the v2 API (the connection URI is checked
    for emptiness before it is set as `DATABASE_URL`); the Developer plan is
    supported. `redis create` shows the right plan and ProdPack price.
  - The MCP server's machine tools drop the `standby-for` argument.
  - `AGENTS.md` is new and only documents upstream's build and test steps.
    No new network access, telemetry, credential handling, vendored binary
    or build-script change.
- **Install:** unchanged. `/usr/bin/flyctl`, the two-line `/usr/bin/fly`
  wrapper, its README and license, no install script, no units, nothing
  else. `check_package` enforces this on the built package.
- **Upstream status:** active, same owner (`superfly`), not archived; no
  change to the release process beyond the workflow action bump above.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-23.

## 0.5.14-1 (2026-11-20)

- **Change:** upstream's 0.5.14, one release on from 0.5.13. The recipe is
  unchanged apart from the version and the source hash.
- **Source:** upstream tag tarball
  `https://github.com/superfly/flyctl/archive/refs/tags/v0.5.14.tar.gz`,
  sha256 `94e239fb2be22e652b5c3845af7aba95e958ba8fa482defb83ccc671d85f6bf1`.
  The archive I downloaded has that hash. Upstream's
  `flyctl_0.5.14_checksums.txt` lists the release binaries, not this tag
  tarball, and the tag is lightweight (it points straight at commit
  `a05c794575d1c88084c240ee0224a0b14f5287ef`). GitHub's attestation lookup for
  the archive answers 404. So I checked the archive against the tag commit's
  tree instead: all 1127 files it holds are byte-identical (same blob hash, no
  extra or missing file) to that commit's tree, so the tarball is exactly the
  tag's tree as GitHub generated it from `superfly/flyctl`. As for 0.5.10,
  which Daniel approved on 2026-11-13, no upstream checksum or build
  attestation covers the source archive, and the pinned hash is the recipe's
  only archive hash.
- **Build and dependencies:** unchanged. Go from source with
  `GOFLAGS=-mod=readonly`, `GOTOOLCHAIN=local`, `CGO_ENABLED=0` and upstream's
  `production` tag and ldflags; makepkg supplies the distribution's flags.
  `go generate ./...` runs genqlient against the bundled `gql/schema.graphql`
  and mockgen, both pinned in `go.mod`. Neither `go.mod` nor `go.sum` appears
  in the diff, so no module was added, removed or bumped: no new dependency
  publisher. The Makefile, `.goreleaser.yml`, `Dockerfile` and `.github/` are
  untouched too.
- **Upstream code read:** I compared `v0.5.13...v0.5.14`, 7 commits and 20
  files, reading the patches rather than the changelog.
  - `ssh console` now checks the credentials the Machines client actually
    sends. `RequireFlapsSession` runs the login and token monitoring as
    `RequireSession` did, then fails the command when the initial discharge
    refresh errored and every permission macaroon in the Machines credential
    still lacks a discharge, instead of letting it go on to an unauthorized
    API call. `MonitorTokens` now also returns that initial discharge error,
    and the agent server, which has no user to tell, discards it.
  - `ssh console` errors gain fixed codes for the workflow spans
    (`internal/tracing/workflow_error.go`): a new `workflow.error.code`
    attribute carrying a name from a closed vocabulary (`ssh_machine_not_found`,
    `ssh_container_prompt_failed` and so on), never the error text or a caller's
    input. A joined failure with mixed causes stays `unknown`, and context
    cancellation is recorded as `canceled` or `deadline_exceeded` without
    assuming the user did it. The codes are the only new telemetry payload.
  - `machine start` treats the Machines API's 409 "machine still attempting to
    start" as a start in progress: it waits for the version it asked for, up to
    a minute, and skips the later `--wait` phase it has already done. Any other
    error, or a machine with no version, still fails.
  - Remote builders that are already `starting` are waited for (a minute's
    budget) instead of being started again, and the wait's error no longer says
    "after restart".
  - Each `fly deploy` lease-acquisition span is now ended (it leaked before) and
    records its error through `RecordError`.
  - A release-command exit-event read is capped at 30 seconds so one stalled
    Machines GET leaves time for another poll; a cancelled or timed-out wait now
    reports the wait's own error instead of the failed read's.
  - Laravel detection builds its assets on Node 22 rather than 18.
  - No new network destination, no new telemetry payload beyond the error-code
    attribute above, no credential handling change, no vendored or obfuscated
    blob, and no change to the build.
- **Install:** unchanged. No install script, units or triggers; the recipe
  still installs `/usr/bin/flyctl`, its `fly` wrapper, the README and the
  license. No `allow` entry or new install path is needed.
- **Upstream status:** active and not archived, same owner `superfly`, same
  release workflow. 0.5.14 was published on 2026-11-19.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-20.

## 0.5.13-1 (2026-11-19)

- **Change:** upstream's 0.5.13, one release on from 0.5.12. The recipe is
  unchanged apart from the version and the source hash.
- **Source:** upstream tag tarball
  `https://github.com/superfly/flyctl/archive/refs/tags/v0.5.13.tar.gz`,
  sha256 `0166b205742b884df5d5314b303ea97e6f38aa2280f8b67420c8cd273174f48a`.
  The archive I downloaded has that hash. Upstream's
  `flyctl_0.5.13_checksums.txt` lists the release binaries, not this tag
  tarball, and the tag is lightweight (it points straight at commit
  `4d21aedc1d751d4d22907298008d615ff8e8d539`, which GitHub reports as
  verified). GitHub's attestation lookup for the archive answers 404. So I
  checked the archive against the tag commit's tree instead: all 1124 files it
  holds are byte-identical (same blob hash, no extra or missing file) to that
  commit's tree, so the tarball is exactly the tag's tree as GitHub generated
  it from `superfly/flyctl`.
- **Build and dependencies:** unchanged. Go from source with
  `GOFLAGS=-mod=readonly`, `GOTOOLCHAIN=local`, `CGO_ENABLED=0` and upstream's
  `production` tag and ldflags; makepkg supplies the distribution's flags.
  `go generate ./...` runs genqlient against the bundled `gql/schema.graphql`
  and mockgen, both pinned in `go.mod`. Neither `go.mod` nor `go.sum` appears
  in the diff, so no module was added, removed or bumped: no new dependency
  publisher.
- **Upstream code read:** I compared `v0.5.12...v0.5.13`, 3 commits and 13
  files, reading the patches rather than the changelog. `fly wireguard list`
  now also shows token-mode tunnels that this machine's agent holds: a new
  `tunnels` command on the agent's local socket returns their name, peer IP
  and endpoint, and the CLI prints them in a second table, or appends them to
  the JSON rows. A missing or older agent is a warning, not an error, and the
  command never starts an agent. The personal org is asked for by its real
  slug. `fly orgs show` gets a spelling fix and singular grammar for one
  member. `machine restart`/`wait` no longer panics when a Machine has no
  config. `wg/state.go` corrects swapped `localpublic`/`localprivate` JSON tags
  in the WireGuard state file, so a state file written by an older flyctl reads
  its two keys the other way round; the next reconnect rewrites it. No new
  network destination (the new command is a local socket, and it builds no
  tunnel), no new telemetry payload, no credential handling change, no
  vendored or obfuscated blob, and no change to the Makefile,
  `.goreleaser.yml` or the release workflow.
- **Install:** unchanged. No install script, units or triggers; the recipe
  still installs `/usr/bin/flyctl`, its `fly` wrapper, the README and the
  license. No `allow` entry or new install path is needed.
- **Upstream status:** active and not archived, same owner `superfly`, same
  release workflow. 0.5.13 was published on 2026-11-18.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-19.

## 0.5.12-1 (2026-11-18)

- **Change:** upstream's 0.5.12, one release on from 0.5.11. The recipe is
  unchanged apart from the version and the source hash.
- **Source:** upstream tag tarball
  `https://github.com/superfly/flyctl/archive/refs/tags/v0.5.12.tar.gz`,
  sha256 `daafb46bf59dac2ad44eebea3db6d1deb0cd9bb835d8b890c9ac43af79885c70`.
  The archive I downloaded has that hash. Upstream's
  `flyctl_0.5.12_checksums.txt` lists the release binaries, not this tag
  tarball, and the tag is lightweight (it points straight at commit
  `23da327392fa656fa77433b18fc37bbbd164e88b`, which GitHub reports as
  verified). GitHub's attestation lookup for the archive answers 404. So I
  checked the archive against the tag commit's tree instead: all 1122 files it
  holds are byte-identical (same blob hash, no extra or missing file) to that
  commit's tree, so the tarball is exactly the tag's tree as GitHub generated
  it from `superfly/flyctl`.
- **Build and dependencies:** unchanged. Go from source with
  `GOFLAGS=-mod=readonly`, `GOTOOLCHAIN=local`, `CGO_ENABLED=0` and upstream's
  `production` tag and ldflags; makepkg supplies the distribution's flags.
  `go generate ./...` runs genqlient against the bundled `gql/schema.graphql`
  and mockgen, both pinned in `go.mod`. Neither `go.mod` nor `go.sum` appears
  in the diff, so no module was added, removed or bumped: no new dependency
  publisher.
- **Upstream code read:** I compared `v0.5.11...v0.5.12`, 6 commits and 56
  files, reading the patches rather than the changelog. It adds a
  `[[cache_disk]]` machine feature (a fly.toml section, `--cache-disk-size`
  and `--cache-disk-path` on `machine run`/`create`/`update`, the same
  arguments in the MCP tools, a cache disk column in `machine status`);
  `machine start --wait`; `deploy --rollback`, which only renames the span and
  requires `--image`; managed Postgres `dev-256` as a hidden plan and
  `--volume-size` no longer defaulted to 10 GB; and a
  `[[cache_disk]]`-aware scale path. Tracing grows: more commands get workflow
  spans (`machine start`/`update`, `mpg restore`, `volumes create`/`extend`,
  `certs add`, `ips allocate`, `ssh console`) through the existing trace
  exporter, and a hidden `fly trace run -- <command>` runs a child process and
  passes it `FLYCTL_TRACEPARENT`/`FLYCTL_TRACESTATE`, reading them back from
  the environment in a child flyctl; span errors stay status-only as before, so
  no new field carries command output. In token-mode WireGuard, a tunnel now
  sends WireGuard to the gateway's own direct IP over UDP when the gateway
  offers one, keeping the websocket for the token exchange and reconnects:
  same Fly gateway, new transport, with a fallback to the websocket proxy when
  there is no direct IP. Launch also stops writing `memory_mb` beside
  `memory`. No new network destination, no new telemetry payload, no
  credential handling change, no vendored or obfuscated blob, and no change to
  the Makefile, `.goreleaser.yml` or the release workflow.
- **Install:** unchanged. No install script, units or triggers; the recipe
  still installs `/usr/bin/flyctl`, its `fly` wrapper, the README and the
  license. No `allow` entry or new install path is needed.
- **Upstream status:** active and not archived, same owner `superfly`, same
  release workflow (releases published by `github-actions[bot]`). 0.5.12 was
  published on 2026-11-17.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-18.

## 0.5.11-1 (2026-11-17)

- **Change:** upstream's 0.5.11, three releases on from 0.5.8 (0.5.9 and
  0.5.10 were never packaged). The recipe is unchanged apart from the version
  and the source hash.
- **Source:** upstream tag tarball
  `https://github.com/superfly/flyctl/archive/refs/tags/v0.5.11.tar.gz`,
  sha256 `cd0f0739e424f47ad9d1de2d8ffc319af7f2947c8c657dd99c19f6d102f45be2`.
  The archive I downloaded has that hash. Upstream's release checksums list
  the release binaries, not this tag tarball, and the tag is unsigned, so
  instead of a checksum file I checked the archive against the tag commit:
  all 1112 files it holds are byte-identical (same blob hash, same mode, no
  extra or missing file) to the tree of commit `459ed4c`, which `v0.5.11`
  points at and which GitHub reports as verified. The tarball is therefore
  exactly the tag's tree, generated by GitHub from `superfly/flyctl` itself.
  This is the provenance question the 0.5.8 and 0.5.10 audits left to Daniel
  (Daniel accepted it there on 2026-11-13); here it is answered yes by the
  tree comparison rather than held.
- **Build and dependencies:** unchanged. Go from source with
  `GOFLAGS=-mod=readonly`, `GOTOOLCHAIN=local`, `CGO_ENABLED=0` and upstream's
  `production` tag and ldflags; makepkg supplies the distribution's flags.
  `go generate ./...` runs genqlient against the bundled
  `gql/schema.graphql` and mockgen, both pinned in `go.mod`. The only module
  change is `github.com/superfly/fly-go` v0.11.8 to v0.12.1, published by
  `superfly`, the same organization as flyctl; `go.sum` carries its hashes
  and nothing else changed. No new dependency publisher.
- **Upstream code read:** I compared `v0.5.8...v0.5.11`, 121 files. It is a
  bug-fix release. The largest part narrows Sentry reporting: a shared
  `internal/sentry/ignore.go` drops expected outcomes (a remote command's
  non-zero exit, an abort, a machine-limit refusal, a canceled command) and
  the app-info helpers report a FlapsError only when it is itself the
  failure. It adds a `fly mpg maintenance-window show|set` command, `--command`
  and `--file` for `fly mpg connect` (psql now stops at the first error,
  `ON_ERROR_STOP=1`, when scripted), provider-scoped add-on lookups for Redis
  so a same-named add-on of another kind is not touched, `fly tokens revoke`
  failing when any token could not be revoked, clearer secret-update errors,
  a Docker BuildKit failover that no longer retries a build that already ran,
  release-command start retries, `fly scale count`/`launch` hints for the
  second machine, `.git` added to the scanner templates' `.dockerignore` and
  a `.dockerignore` for scanner-generated Dockerfiles, and an unknown-subcommand
  error for help-only command groups. It also wraps six commands (`machine
  run`, `scale count`, `mpg create`/`attach`, `volumes create`, `secrets set`)
  in OpenTelemetry workflow spans through the existing trace exporter; the
  spans record a status only, and the code says so explicitly because command
  errors can carry secrets or connection strings. No new network destination,
  no new telemetry field, no vendored blob, no `curl | sh`, and no change to
  the Makefile, `.goreleaser.yml` or the release workflow.
- **Install:** unchanged. No install script, units or triggers; the recipe
  still installs `/usr/bin/flyctl`, its `fly` wrapper, the README and the
  license. No `allow` entry or new install path is needed.
- **Upstream status:** active and not archived, same owner `superfly`, same
  release workflow (releases published by `github-actions[bot]`). 0.5.11 was
  published on 2026-11-16.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-17.

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
