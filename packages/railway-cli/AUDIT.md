# railway-cli: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 5.77.0-1 (2026-11-28)

- **Change:** upstream's 5.77.0, three releases on from 5.76.0 (5.76.1 and
  5.76.2 were cut in between and nvchecker proposed the newest). The bump
  moves `package.env`, `arch/PKGBUILD` and `rpm/railway-cli.spec` to the new
  tag, its sha256 and a spec changelog line; nothing else changes.
- **Source:** upstream's static release binary:
  `https://github.com/railwayapp/cli/releases/download/v5.77.0/railway-v5.77.0-x86_64-unknown-linux-musl.tar.gz`,
  sha256 `65d52da2650171a3bf0c752e3eb6f533a948b0aaf7475f48f1cb26c8c6c5fed9`.
  The archive I downloaded has that hash, and it matches the `digest` GitHub
  reports for the release asset, which `github-actions[bot]` uploaded with the
  release on 2026-11-28. The project's own organization, `railwayapp`.
- **Attestation:** `attest=release`; `gh release verify-asset v5.77.0` for the
  pinned file succeeded ("present in release v5.77.0"), resolving the tag to
  `363de32c`. I checked what else the digest carries: GitHub holds one
  attestation for it, of type `https://in-toto.io/attestation/release/v0.2`
  (the immutable-release statement naming every asset), and no SLSA build
  provenance, so `release` is the strongest attestation upstream offers here.
  `lint.sh` repeats the check. `v5.77.0` is an annotated tag object created by
  `github-actions[bot]` on 2026-11-28; the release attestation, not the tag,
  is what the recipe pins.
- **Binary:** static-pie (musl), x86-64, stripped by upstream, no shared
  libraries, and still one file in the archive (`railway`, mode 0755, no
  README or license). 21685688 bytes against 21673400 for 5.76.0, and the
  `.tar.gz` is 9460891 bytes against 9460217, so the archive grew only with
  the binary.
- **Build and dependencies:** none in depot. `Cargo.lock` changes only the
  `railwayapp` package version; no crate was added, removed or bumped, so no
  new dependency publisher. `Cargo.toml` and `package.json` change the version
  string only. No `.github`, `Makefile` or build-script file appears in the
  diff.
- **Upstream code read:** I read the whole `v5.76.0...v5.77.0` diff, 7 commits
  and 17 files, two of them release commits.
  - `railway agent` no longer prints the billing notice or waits five seconds
    before it first creates the environment's cloud agent: the notice, the
    wait and its key handling are deleted, `--accept` is kept but hidden and
    ignored, and the agent starts at once. This is upstream's product
    decision, and it changes nothing depot installs: the package is the CLI as
    upstream builds it, and nothing runs it here.
  - A code request that `railway agent` hands to the agent dashboard is now
    followed in the terminal (`src/commands/agent/follow.rs`, new, 431 lines).
    When stdin, stdout and stderr are terminals and `--json` is not set, it
    polls the run on the same backboard host through the existing
    `task::fetch`, prints the tools the run uses, answers approvals
    (allow/deny) and the agent's own `requester` questions inline, and leaves
    forms from other servers to the dashboard so nothing secret is typed into
    a terminal. Ctrl-C detaches and the run keeps going. At the end it prints
    the run's summary and the machine's preview domain, which comes from a new
    `CloudAgentPreview` GraphQL query (`cloudAgent.domain`) against the same
    backboard. `--json` now carries `cloudAgentId` and `sessionId` in the
    handoff. No new host: I compared the URL prefixes in the 5.76.0 and 5.77.0
    binaries and they are the same hosts.
  - IaC: `buildCommand: null` or `""` now clears the live build command while
    an omitted key keeps it, normalized so a landed clear is not planned
    again; a database created with a pinned image re-asserts its `source` in
    the same change set instead of drifting on the next plan; a project
    definition may carry `id`, and plan and apply now refuse a file pinned to
    a different project than the directory is linked to (`project("name")` is
    only a label); and `railway config migrate` cutover now clears the stored
    Config File path without starting a deployment, as its text says, and no
    longer skips paths that are not Config-as-Code files, so any stored path is
    cut over.
  - No new telemetry, credential handling, vendored blob, `curl | sh` or
    change to the Makefile, the release workflow or CI. The added tests are
    unit tests.
- **Install:** `/usr/bin/railway` only. No scriptlets, units, links or
  additional paths, so no `allow` entry is needed and none changed.
- **Upstream status:** active and not archived, same owner `railwayapp`, same
  release workflow (releases published by `github-actions[bot]`); 5.77.0 was
  published on 2026-11-28.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-28.

## 5.76.0-1 (2026-11-27)

- **Change:** upstream's 5.76.0, one release on from 5.75.0. The bump moves
  `package.env`, `arch/PKGBUILD` and `rpm/railway-cli.spec` to the new tag,
  its sha256 and a spec changelog line; nothing else changes.
- **Source:** upstream's static release binary:
  `https://github.com/railwayapp/cli/releases/download/v5.76.0/railway-v5.76.0-x86_64-unknown-linux-musl.tar.gz`,
  sha256 `c5877d3b56c4f941b075ff5167db1b4f19219247a179fed338fc7b2bdbf54d29`.
  The archive I downloaded has that hash, and it matches the `digest` GitHub
  reports for the release asset, which `github-actions[bot]` uploaded with the
  release on 2026-11-26. The project's own organization, `railwayapp`.
- **Attestation:** `attest=release`; `gh release verify-asset v5.76.0` for the
  pinned file succeeded ("present in release v5.76.0"), resolving the tag to
  `cfece096`. I checked what else the digest carries: GitHub holds one
  attestation for it, of type `https://in-toto.io/attestation/release/v0.2`
  (the immutable-release statement naming every asset), and no SLSA build
  provenance, so `release` is the strongest attestation upstream offers here.
  `lint.sh` repeats the check. `v5.76.0` is an annotated tag object created by
  `github-actions[bot]` on 2026-11-26; the release attestation, not the tag,
  is what the recipe pins.
- **Binary:** static-pie (musl), x86-64, stripped by upstream, no shared
  libraries, and still one file in the archive (`railway`, mode 0755, no
  README or license). 21673400 bytes against 21661112 for 5.75.0.
- **Build and dependencies:** none in depot. `Cargo.lock` changes only the
  `railwayapp` package version; no crate was added, removed or bumped, so no
  new dependency publisher. `Cargo.toml` and `package.json` change the version
  string only. No `.github`, `Makefile` or build-script file appears in the
  diff.
- **Upstream code read:** I read the whole `v5.75.0...v5.76.0` diff, 2 commits
  and 7 files, plus the one-line `src/gql/schema.json` change, which I compared
  type by type: it adds `dashboardHandoff` to `CloudAgentTaskDispatchInput`
  and `dashboardRunUrl` to `CloudAgentTaskHandle`, and nothing else.
  - `railway agent` now hands code requests to the agent dashboard. A new
    thread (`--thread-id` unset) sends `dashboardHandoff: true` with the same
    `CloudAgentTaskDispatch` mutation it already called; when the API answers
    with a `dashboardRunUrl`, the CLI prints that link and returns a
    `HANDED_OFF` status instead of waiting here, and `--json` carries the link
    in `dashboardRunUrl` with no thread id. The URL is printed, never fetched
    or opened, and the only network call is the dispatch to the same backboard
    host as before.
  - The rest is the help text for that path and a unit test for the JSON
    shape. No new telemetry, credential handling, vendored blob, `curl | sh`
    or change to the Makefile, the release workflow or CI. I compared the URL
    and host strings of the 5.75.0 and 5.76.0 binaries: the same 14 hosts in
    both.
- **Install:** `/usr/bin/railway` only. No scriptlets, units, links or
  additional paths, so no `allow` entry is needed and none changed.
- **Upstream status:** active and not archived, same owner `railwayapp`, same
  release workflow (releases published by `github-actions[bot]`); 5.76.0 was
  published on 2026-11-26.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-27.

## 5.75.0-1 (2026-11-18)

- **Change:** upstream's 5.75.0, one release on from 5.74.1. The bump moves
  `package.env`, `arch/PKGBUILD` and `rpm/railway-cli.spec` to the new tag,
  its sha256 and a spec changelog line; nothing else changes.
- **Source:** upstream's static release binary:
  `https://github.com/railwayapp/cli/releases/download/v5.75.0/railway-v5.75.0-x86_64-unknown-linux-musl.tar.gz`,
  sha256 `ba5d9fb5dce1c59789f4216e6b754becd75025ed740388452be55aae83720400`.
  The archive I downloaded has that hash, and it matches the `digest` GitHub
  reports for the release asset, which `github-actions[bot]` uploaded with the
  release on 2026-11-17. The project's own organization, `railwayapp`.
- **Attestation:** `attest=release`; `gh release verify-asset v5.75.0` for the
  pinned file succeeded ("present in release v5.75.0"). I checked what else
  the digest carries: GitHub holds one attestation for it, of type
  `https://in-toto.io/attestation/release/v0.2` (the immutable-release
  statement naming every asset), and no SLSA build provenance, so `release`
  is the strongest attestation upstream offers here. `lint.sh` repeats the
  check. `v5.75.0` is an unsigned annotated tag object created by
  `github-actions[bot]`, pointing at the unsigned release commit `f3aa334`;
  the release attestation, not the tag, is what the recipe pins.
- **Binary:** static-pie (musl), x86-64, stripped by upstream, no shared
  libraries, and still one file in the archive (`railway`, mode 0755, no
  README or license). 21661112 bytes against 21636536 for 5.74.1.
- **Build and dependencies:** none in depot. `Cargo.lock` changes only the
  `railwayapp` package version; no crate was added, removed or bumped, so no
  new dependency publisher. `Cargo.toml` and `package.json` change the version
  string only. No `.github`, `Makefile` or build-script file appears in the
  diff.
- **Upstream code read:** I read the whole `v5.74.1...v5.75.0` diff, 4 commits
  and 30 files, plus the one-line change to `src/gql/schema.json` (a
  `cloudAgent.region` field added, `baseImageDigest` dropped from the sandbox
  template input). It takes cloud agents and sandboxes out of experimental:
  - The "experimental" warnings and the `CLOUD_AGENTS` feature-flag preflight
    are gone (`src/commands/cloud_agent/access.rs`, its `CloudAgentAccess`
    query and its `flag_missing` telemetry event are deleted). Telemetry
    shrinks; nothing is added.
  - Agents now sleep on their own: after 5 idle minutes (no SSH client,
    almost no network traffic, no coding agent working or waiting) the
    platform stops compute, which ends running processes and keeps the disk,
    and connecting wakes it. Agents created before the 2026-10-08 deploy keep
    the spec they were created with and never do. The CLI only reads that from
    age (`ca::sleeps_when_idle`, cutoff `2026-10-08T00:37:00Z`) to word its
    messages. `--keep-awake` is now accepted and ignored, `ca sleep` reads the
    status first and skips the pre-sleep SSH flush for an agent that is not
    running (an SSH connection would wake it), and `ca sleep --all` acts only
    on running agents. This is a product behaviour change on Railway's own
    platform, not something depot installs.
  - Sandboxes and agents now print one shared create and disconnect block
    (`src/commands/output/machine.rs`); `ca create --json` gains `region` and
    `domains` from a new `CloudAgentPlacement` query against the same
    backboard, and the `Sandbox` query gains `region`, `environmentId`,
    `createdAt`, `idleTimeoutMinutes` and `domains`. `sandbox create` and
    `sandbox fork` wait for RUNNING by default (5 minute cap, 0.5s to 2s
    polls) with a new `--no-wait`; `--base-image-digest` is retired, hidden
    and refused with an explanation, and a template stored with one is
    refused by name instead of sending a checkpoint that was never built.
  - The Python bootstrap scripts that run on the agent VM (`codex.py`,
    `opencode.py`) now find the process listening on the server port through
    `/proc/net/tcp` and `/proc/*/fd`, and adopt a server that express-agent
    restarted after a power-off. Adoption only happens when that listener
    accepts the saved token (or, for OpenCode, the saved credentials and
    refuses requests without them), and only `inspect` treats it as
    read-only; the others save the new PID and process group. All of it is
    local to the VM: no new network destination, no credential sent anywhere
    new.
  No vendored or obfuscated blob, no `curl | sh`, no change to the Makefile,
  the release workflow or CI. I compared the URL and host strings of the
  5.74.1 and 5.75.0 binaries: the same set (Railway's API and backboard, MCP,
  GitHub, raw.githubusercontent, npm, docs), and the only "new" hits are
  adjacent string literals from the string table, not hosts.
- **Install:** `/usr/bin/railway` only. No scriptlets, units, links or
  additional paths, so no `allow` entry is needed and none changed.
- **Upstream status:** active and not archived, same owner `railwayapp`, same
  release workflow (releases published by `github-actions[bot]`); 5.75.0 was
  published on 2026-11-17.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-18.

## 5.74.1-1 (2026-11-17)

- **Change:** upstream's 5.74.1, one release on from 5.74.0. The bump moves
  `package.env`, `arch/PKGBUILD` and `rpm/railway-cli.spec` to the new tag,
  its sha256 and a spec changelog line; nothing else changes.
- **Source:** upstream's static release binary:
  `https://github.com/railwayapp/cli/releases/download/v5.74.1/railway-v5.74.1-x86_64-unknown-linux-musl.tar.gz`,
  sha256 `57911c6d61881e8f47d00df42f02b94d85b5e82dcd96b8bc84bd121be58a8332`.
  The archive I downloaded has that hash, and it matches the `digest` GitHub
  reports for the release asset, which `github-actions[bot]` uploaded with the
  release on 2026-11-16. The project's own organization, `railwayapp`.
- **Attestation:** `attest=release`; `gh release verify-asset v5.74.1` for the
  pinned file succeeded ("present in release v5.74.1"). I checked what else
  the digest carries: GitHub holds one attestation for it, of type
  `https://in-toto.io/attestation/release/v0.2` (the immutable-release
  statement naming every asset), and no SLSA build provenance, so `release`
  is the strongest attestation upstream offers here. `lint.sh` repeats the
  check. The tag commit is unsigned, as it was for 5.74.0; the release
  attestation, not the tag, is what the recipe pins.
- **Binary:** static-pie (musl), x86-64, stripped by upstream, no shared
  libraries, and still one file in the archive (`railway`, mode 0755, no
  README or license). 21636536 bytes against 21611928 for 5.74.0.
- **Build and dependencies:** none in depot. `Cargo.lock` changes only the
  `railwayapp` package version; no crate was added, removed or bumped, so no
  new dependency publisher. `Cargo.toml` and `package.json` change the version
  string only. No `.github`, `Makefile` or build-script file appears in the
  diff.
- **Upstream code read:** I read the whole `v5.74.0...v5.74.1` diff, 9 files,
  all under `src/iac` and `src/commands/config` plus the three version files.
  It is three bug fixes, matching the release notes:
  - `config` pull now renders a database's `limitOverride` and
    `multiRegionConfig`, and for Python emits a real `with_fields(deploy=...)`
    assignment instead of a comment that the next plan dropped. It also
    renders a database's PITR variables (`WAL_ARCHIVE_*`, `WAL_RECOVER_FROM_*`,
    the MySQL equivalents and the recovery-target-time keys) as
    `variables`/`.env`, and turns any of those whose name looks like a
    credential into `preserve` rather than writing a decrypted secret into the
    file.
  - The change set stops treating an existing generated secret as a change
    (a missing stored generator counts as unchanged unless `rotate` is asked
    for; deleting `rotate` does not mint a new secret), keeps template
    credentials and unmentioned variables when a database file omits them,
    treats an explicit `null` as a delete, and only drops `limitOverride`
    when the file does not mention it.
  - The engine reads `sourceEnvironmentName` instead of resolving the
    `sourceEnvironment` node, so a project token pinned to its own environment
    can plan a copied environment; it falls back to the relation, then drops
    it on `Unauthorized`, and `ctx.pr.base` throws with an explanation rather
    than evaluating to null.
  No new network destination, telemetry field, credential export, install
  step or vendored blob. I compared the URL and host strings of the 5.74.0
  and 5.74.1 binaries: the same set (Railway's API and backboard, MCP,
  GitHub, npm, docs), and the only "new" hits are adjacent string literals
  from the string table, not hosts. The GraphQL query against Railway's API
  gains one field name and nothing else.
- **Install:** `/usr/bin/railway` only. No scriptlets, units, links or
  additional paths, so no `allow` entry is needed and none changed.
- **Upstream status:** active and not archived, same owner `railwayapp`, same
  release workflow (releases published by `github-actions[bot]`); 5.74.1 was
  published on 2026-11-16.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-17.

## 5.74.0-1 (2026-11-13)

- **Why depot ships it:** Daniel's agents deploy to Railway from `bridge`
  and `supercomputer` (the service migration in factory's
  `docs/railway-migration.md`). Arch has no Railway CLI: its `railway` is an
  unrelated GNOME app, so the package is `railway-cli` on every target. The
  binary is `railway`.
- **Source:** upstream's static release binary:
  `https://github.com/railwayapp/cli/releases/download/v5.74.0/railway-v5.74.0-x86_64-unknown-linux-musl.tar.gz`,
  sha256 `0fc8d11c416b666d4963e9727581b62ad136f5bd83df79dbd85d66f9e4b845f7`.
  The release asset's GitHub digest matches the recipe. The release carries
  GitHub's immutable-release attestation; `lint.sh` verifies this exact asset
  with `gh release verify-asset`.
- **Binary:** static-pie (musl), x86-64, stripped by upstream; no shared
  libraries. It is upstream's binary and is not rebuilt by depot.
- **Build and dependencies:** none in depot. `Cargo.toml`, `Cargo.lock`, and
  `package.json` only change the version in this diff; no new dependency
  publishers were added. Upstream's release workflow changes only to declare
  least-privilege GitHub token permissions for release and cargo-audit jobs;
  the build commands are unchanged.
- **Upstream code read:** the full diff `v5.71.0...v5.74.0`, including the
  task, MCP, upload, telemetry, and release-workflow changes.
  - New `railway ca task` commands send a prompt, project and environment IDs,
    and any selected repo/service to Railway's backboard API. Optional local
    images are read and sent inline; image URLs are passed to Railway to fetch.
    Tasks continue on Railway after the CLI exits by default. A new cloud-agent
    VM is billed while active and sleeps after five minutes idle. The task
    command asks first when interactive and refuses to create a new agent from
    a non-interactive shell unless `--accept` is passed.
  - `railway agent` now runs those tasks on a shared cloud-agent VM instead of
    using the former direct chat flow. It sends the user's message to Railway;
    the code notes that the agent can see the whole environment. The VM may be
    created and billed on the first message. **Not sure:** in a non-interactive
    shell, `railway agent -p ...` prints a notice, waits five seconds, then
    starts the VM automatically unless interrupted; it does not require
    `--accept`. This is a new billing and data-sharing behavior that needs
    Daniel's approval.
  - The existing MCP proxy now reports unrecovered upstream failures through
    its existing CLI telemetry row. The new text is a fixed low-cardinality
    class, not a prompt, URL, identifier, or response body. MCP boolean parsing
    accepts the strings `true` and `false` for confirmation fields, but an
    irreversible action still requires an explicit true value.
  - Deployment tarball creation now refuses symlinks whose resolved target is
    outside the project root and tells the user which links were omitted.
    Other changes add task status/approval commands, improve MCP handshake
    compatibility, and harden volume-download path handling.
- **Install:** `/usr/bin/railway` only; the release archive carries no README
  or license file. No scriptlets, units, links, or additional paths.
- **Network behavior:** normal Railway API and updater behavior from 5.71.0
  remains. The new cloud-agent task and prompt/image transfer only occur when
  those commands are used, but may persist and incur charges after the CLI
  exits. The package-manager install remains protected from self-update.
- **Upstream status:** active, same owner, not archived. The release workflow's
  token permissions are now explicit and narrower; no new publisher or build
  service was added.
- **Audit decision:** held. The new cloud-agent flow sends user prompts and
  optional images to Railway, can leave billed work running in the background,
  and `railway agent -p` can start a billed VM after a five-second notice in
  non-interactive use. Ask Daniel whether this behavior is acceptable.
- **Reviewed by:** GPT-6 Luna for Daniel, 2026-11-13.

## 5.71.0-2 (2026-11-09)

- **Change:** upstream's release binary instead of a source build (Daniel,
  2026-11-09: a package whose upstream binary carries a GitHub attestation
  uses that binary). The version, and so the upstream code, is the one
  audited in 5.71.0-1 below.
- **Source:**
  `https://github.com/railwayapp/cli/releases/download/v5.71.0/railway-v5.71.0-x86_64-unknown-linux-musl.tar.gz`,
  sha256 `2e682fd2ddf8d6fdf9e46d9d99d99646ff0022a6abb0c2bca93011348a269fb9`:
  the `railway` binary alone.
- **Attestation:** GitHub's immutable-release attestation
  (`https://in-toto.io/attestation/release/v0.2`) lists this file, by
  sha256, as an asset of release `v5.71.0` in `railwayapp/cli`. `lint.sh`
  checks it with `gh release verify-asset` on every run. It proves the file
  is the unchanged asset upstream published with that tag. It does not prove
  upstream's CI built it from the tag's source: Daniel accepted that on
  2026-11-09 (any GitHub attestation counts).
- **Binary:** static-pie (musl), x86-64, stripped by upstream: no shared
  libraries, so no runtime dependencies on any target. It is built with
  upstream's own release profile (`lto = "fat"`, `opt-level = "z"`), not the
  distributions' flags. The musl build was chosen over `linux-gnu`, which is
  attested too, so a glibc on the target can never be too old.
- **Install:** `/usr/bin/railway` only; the tarball carries no README or
  license file. `check_package` enforces it. The telemetry and updater notes
  below still hold.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-09.

## 5.71.0-1 (2026-11-03)

- **Why depot ships it:** Daniel's agents deploy to Railway from `bridge`
  and `supercomputer` (the service migration in factory's
  `docs/railway-migration.md`). Arch has no Railway CLI: its `railway` is an
  unrelated GNOME app, so the package is `railway-cli` on every target. The
  binary is `railway`.
- **Source:** upstream tag tarball
  `https://github.com/railwayapp/cli/archive/refs/tags/v5.71.0.tar.gz`,
  sha256 `953b79a2d4422344a64ef2929487a66ebc3e1f67b4024116a55c8da8eebffba3`.
  The project's own organization; the tarball unpacks to `cli-5.71.0`.
- **Starting recipe:** written for depot, on the model of `dufs` (Arch) and
  `starship` (Fedora). The AUR's `railway-cli` was not copied.
- **Build:** `cargo build --locked --release` (Arch: `cargo fetch --locked`,
  then `--frozen`). Crates come from crates.io, pinned by upstream's
  `Cargo.lock`: 701 sourced entries, all `registry+crates.io`, no git
  dependencies. Upstream's release profile is `lto = "fat"`, `opt-level =
  "z"`, `panic = "abort"`. `rusqlite` bundles SQLite, which needs `gcc`.
  TLS is rustls with `ring` (no OpenSSL). Needs Rust 1.85 or newer (edition
  2024).
- **Upstream code read:** `build.rs` only sets `rerun-if-changed` and exports
  the target triple; no network. The tarball also carries `install.sh`,
  `agents.sh`, `v2.sh` and an npm wrapper; the build runs none of them.
  At run time the CLI talks to Railway's API; it spawns `git`, `ps`,
  `python3`, `go` and `node` for the commands that use them (the
  infrastructure-as-code evaluators in `src/iac`, and telemetry's
  process-ancestry check). Only the process spawns were grepped, not every
  command's behavior.
- **Telemetry and updates:** telemetry is on by default and is switched off by
  `RAILWAY_NO_TELEMETRY=1` or `DO_NOT_TRACK=1`. The self-updater
  (GitHub releases) is switched off by `RAILWAY_NO_AUTO_UPDATE=1`. A binary
  under `/usr/bin` is classified `InstallMethod::Unknown`, which the updater
  does not replace, so the package manager stays in charge. Machines that
  install this should still set both variables.
- **Install:** no install script, no units, nothing outside `/usr/bin/railway`,
  the README and the license. `check_package` enforces this on the built
  package.
- **Upstream status:** active (5.71.0 is the latest release), same owner, not
  archived. Railway disclosed a platform incident in October 2026 that
  exposed customer environment variables; it concerns Railway's servers, not
  the CLI's source or releases.
- **Not built:** Debian 13 (instabox `t3` has no Railway work); add the
  `debian/` recipe when it does.
- **Reviewed by:** Claude (Sonnet 5.5) for Daniel, 2026-11-03.
