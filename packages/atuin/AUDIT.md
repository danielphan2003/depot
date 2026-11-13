# atuin: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 18.24.8-1 (2026-11-13)

- **Why depot ships it:** Fedora 44's atuin (rpm 18.12.1, from Fedora's
  package index, 2026-11-10) does not work with nushell 0.116, also shipped
  by depot. Its `atuin init nu` calls `job spawn -t`, and nushell renamed that flag to
  `--description` (`-d`) in 0.112: a parse error that stops nushell at start.
  It also names two keybindings `atuin`, which nushell 0.116 warns about on
  every start. Daniel asked, on 2026-11-10, for the current atuin on Debian
  too.
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release
  binaries, and build from source only when that is needed. Daniel,
  2026-11-09: a package whose upstream binary carries a GitHub attestation
  uses that binary. This one does.
- **Source:**
  `https://github.com/atuinsh/atuin/releases/download/v18.24.8/atuin-x86_64-unknown-linux-musl.tar.gz`
  from the GitHub release of `atuinsh/atuin` (the project's own
  organization), sha256
  `f8dfc3f9d27cadc2e2c9d489394ef7c568291e2382a4d184865701bf1a4ac30a`. It
  matches the release's `sha256.sum` and the asset's own `.sha256` file.
- **Attestation:** SLSA build provenance (`https://slsa.dev/provenance/v1`)
  signed by
  `atuinsh/atuin/.github/workflows/release.yml@refs/tags/v18.24.8` was
  verified for the release archive and its `atuin` binary. `lint.sh` checks
  the archive against this workflow and tag on every run.
- **Binary:** static-pie (musl), x86-64: no interpreter and no shared
  libraries. It is upstream's release binary, not rebuilt by depot.
- **Build:** none. The recipes unpack the archive and install the binary as
  it is, with no network access beyond the pinned download.
- **Upstream change read:** the full diff `v18.24.6...v18.24.8`, including
  the source, lockfile, and release workflow changes. No vendored binary blob
  was added.
  - New project config: upstream now reads `atuin.lua` and `.atuin.lua` files
    from project directories without prompting. The Luau VM has only string,
    table, and math libraries, calls `sandbox(true)`, has a memory limit and
    a half-second time limit, and exposes no file access, `require`, or clock.
    The file can set organization slugs for sharing threads from that project.
  - New network and credential surface: the former opt-in Octavo setting is
    renamed to `[teams]`, with `teams.enabled` and `teams.upload_output` both
    defaulting to false; the old `[octavo]` setting is read as a legacy name.
    When enabled, Atuin for Teams uploads shell history and agent threads to
    the configured hub. Project config can queue thread shares with its
    listed organizations. MCP clients can also forward thread-tool calls to
    the Teams MCP server; that path uses the sync token and is only supplied
    while Teams is enabled. These are opt-in, but include private command and
    agent-session data when enabled.
  - Dependencies: the lockfile adds crates for Luau config execution and the
    MCP client transport, including `mlua`, `mlua-sys`, `luau0-src`,
    `serde-value`, `erased-serde`, `bstr`, `inquire`, and `sse-stream`, plus
    their transitive dependencies. I have not verified the publishers of all
    newly resolved crates, so the dependency-publisher checklist answer is
    **not sure**.
  - Release process: upstream adds a musl C++ toolchain download to its
    release build, pinned by architecture-specific hashes, and adds automatic
    WinGet submissions through a new workflow. That workflow downloads Komac
    2.17.2 with a pinned hash and uses `WINGET_TOKEN` to open pull requests in
    `microsoft/winget-pkgs`. This is a material change to upstream's release
    workflow and third-party publishing surface.
- **Install:** `/usr/bin/atuin` plus the license and README; no scriptlets,
  units, or links. The recipes still install only plain files in the allowed
  locations. The Debian package also carries the upstream changelog.
- **Allowed paths:** none.
- **Network behavior:** `sync_address` defaults to Atuin's hosted server and
  `update_check` is on by default (a version query); both are user
  configuration. Teams uploads and remote MCP forwarding are disabled by
  default as described above. The self-updater refuses to replace a
  package-manager install.
- **Upstream status:** active, same organization, several releases a month.
- **Audit decision:** held. The new dependency publishers are not fully
  verified, and the release workflow now automatically submits packages to
  WinGet. Ask Daniel before merging.
- **Reviewed by:** OpenCode (GPT-6 Luna) for Daniel, 2026-11-13.

## 18.24.6-1 (2026-11-10)

- **Why depot ships it:** Fedora 44's atuin (rpm 18.12.1, from Fedora's
  package index, 2026-11-10) does not work with nushell 0.116, which depot
  also ships. Its `atuin init nu` calls `job spawn -t atuin`, and nushell
  renamed that flag to `--description` (`-d`) in 0.112: a parse error that
  stops nushell at start. It also names two keybindings `atuin`, which
  nushell 0.116 warns about on every start. The releases that call `job spawn`
  up to 18.12.1 emit `-t`; 18.13.0 to 18.13.2 emit `-d`; 18.13.3 and newer drop
  the tag; older ones, such as Debian's 18.6.1, never call it. 18.24.6
  parses and starts without warnings under nushell 0.116.1. Recipes exist for
  Fedora and Debian; Arch ships atuin 18.24.6 itself.
  - Debian 13 ships 18.6.1 (Debian's package index). It does not call
    `job spawn`, and works with nushell 0.116.1 but warns twice on every
    start (a deprecated flag, and the same duplicate keybinding name). Daniel
    asked, on 2026-11-10, for the current atuin there too.
  - depot's apt pin is below Debian's packages, so a machine installs Debian's
    atuin of the same name over depot's. The first draft's Debian recipe
    failed CI's install test for that reason, 2026-11-10. The recipe is back
    with an `allow` entry, `override debian`, which makes the install test pin
    depot's atuin above Debian's as a machine does that lists atuin. A machine
    that does not list it keeps Debian's.
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release
  binaries, and build from source only when that is needed. Daniel,
  2026-11-09: a package whose upstream binary carries a GitHub attestation
  uses that binary. This one does.
- **Source:**
  `https://github.com/atuinsh/atuin/releases/download/v18.24.6/atuin-x86_64-unknown-linux-musl.tar.gz`
  from the GitHub release of `atuinsh/atuin` (the project's own
  organization), sha256
  `49b6e7a93cd6d8c77ee02bdb0eef0acff4c80ddaa0efb00c8179285771043698`. It
  matches the release's `sha256.sum` and the asset's own `.sha256` file.
- **Attestation:** SLSA build provenance (`https://slsa.dev/provenance/v1`)
  signed by `atuinsh/atuin/.github/workflows/release.yml@refs/tags/v18.24.6`,
  source commit `c71cd7baad5aaf0ff4d19db369d247f08da76ec9`, with this file's
  `atuin` binary and the archive among its subjects. `lint.sh` checks it with
  `gh attestation verify`, pinned to that workflow and tag, on every run.
  This is the stronger kind: it proves upstream's workflow built the file
  from the tag, not only that upstream published it. The release itself is not
  an immutable release, so `attest=release` would not have worked.
- **Binary:** static-pie (musl), x86-64: no interpreter and no shared
  libraries, so no library dependencies (the rpm records only
  `rtld(GNU_HASH)`, which glibc provides). The musl build was chosen over
  `linux-gnu`, which is attested too, so the target's glibc does not matter
  (as `railway-cli` and `zellij`). It is built with upstream's release
  profile, not the distributions' flags. Upstream strips it; depot does not
  strip it again (54 MB installed).
- **Build:** none. The recipes unpack the archive and install the binary as
  it is, with no network access beyond the pinned download.
- **Upstream change read:** this is the package's first entry, so the baseline
  is the previous release: the diff `v18.24.5...v18.24.6` (28 commits, about
  100 files). Not read: the rest of the code base. The attestation ties the
  binary to the tagged source and upstream's workflow; it does not say the
  source is benign.
  - Build and CI: no change under `.github/`, `dist-workspace.toml`, scripts or
    a Dockerfile. `crates/atuin-octavo/build.rs` gains one `type_attribute`
    call (a clippy allow on a generated enum). No binary or vendored blobs were added: new files are Rust and SQL
    sources (and a test-regression text file); the protobuf sources changed.
  - Dependencies: `const_format` and its helpers `const_format_proc_macros`,
    `konst` and `konst_macro_rules` are new, all compile-time string
    formatting, with no network or file access. `rmcp` goes 3.3.0 to 3.9.0
    (upstream says for three advisories), and `hyper-util` and
    `unicode-normalization` get patch bumps. `deny.toml` ignores RUSTSEC-2026-0459
    (bundled SQLite) with a written reason: it needs a crafted database file
    written by the same user.
  - New network and telemetry surface: the release now compiles in "octavo"
    (`crates/atuin-octavo`, `crates/atuin-daemon/src/octavo`), which uploads
    shell history, optionally command output, and AI-agent session threads to
    Atuin's hub. It is off unless the user sets `octavo.enabled`, which
    `atuin config enable octavo` does after a prompt that defaults to no.
    Checked, not only taken from the commit message (#4693): in the source,
    `octavo.enabled` and `octavo.upload_output` default to `false`
    (`settings.rs`), and `Octavo::open` returns the no-op client unless
    `octavo.enabled` is set or an `octavo.db` queue file exists
    (`crates/atuin-daemon/src/octavo/mod.rs`). Ran the binary with a fresh home
    and no network namespace: `init nu`, `history start`, `history end` and
    `search` work, and the only files created are local databases and config,
    with no `octavo.db`. The code to upload is still in the binary, so
    **keep `octavo.enabled` off** unless an upload is wanted. Arch's package
    has the same build.
  - Not present in older atuin: 18.12.1 has none of this. Upgrading adds the
    opt-in upload feature, the `ai`, `mcp`, `setup` and `config` subcommands
    (18.12.1 has `daemon` only), and a one-way local database migration (see
    Install).
- **Install:** `/usr/bin/atuin` plus the license and README; no scriptlets, no
  units, no links, which `check_package` enforces. `CHANGELOG.md` is left out
  of the rpm; the deb ships it as the upstream changelog (debhelper's
  default). `atuin-server` is a separate archive and is not packaged. Built
  and installed in clean `fedora:44` and `debian:trixie` containers on
  2026-11-10 (the deb with the pin exception in place), and `test.sh`
  passes: the binary runs, and `atuin init nu` output passes `nu-check`.
  It starts cleanly under nushell 0.116.1, with no `job spawn -t` and no
  warnings. **Upgrading from an older atuin is one-way for the local
  database:** 18.24.6 migrates an 18.12.1 database in place, and 18.12.1 then
  fails with `migration 20260224000100 was previously applied but is missing`
  (tried 2026-11-10). To roll back to an older atuin, move
  `~/.local/share/atuin/*.db` aside (sync again if logged in).
- **Allowed paths:** none beyond the defaults. The `allow` file carries only
  `override debian` (Daniel asked, 2026-11-10, for depot's atuin on Debian; this
  entry is how, and his merge of the PR approves it). It grants no path and
  no relation, and changes nothing about what the package may contain: it
  only has the install test pin `atuin` at priority 600 for its Debian run.
  On a machine the same exception is opt-in by exact name, so no other depot
  package can replace a Debian one. The cost of opting in is that the machine
  takes `atuin` updates from depot, not from Debian, which no longer
  updates it on that machine.
- **Network behavior:** `sync_address` defaults to Atuin's hosted server and
  `update_check` is on by default (a version query); both are user
  configuration. The self-updater, `atuin update`, refuses to run without the receipt that
  upstream's installer script writes, and tells the user to update through
  their package manager, so an install from depot will not replace itself
  (`crates/atuin/src/command/client/update.rs` at the tag).
- **Upstream status:** active, same organization, several releases a month.
- **Reviewed by:** Claude (Sonnet 5.5) for Daniel, 2026-11-10.
