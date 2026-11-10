# atuin: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 18.24.6-1 (2026-11-10)

- **Why depot ships it:** Fedora 44's atuin (rpm 18.12.1, from Fedora's
  package index, 2026-11-10) does not work with nushell 0.116, which depot
  also ships. Its `atuin init nu` calls `job spawn -t atuin`, and nushell
  renamed that flag to `--description` (`-d`) in 0.112: a parse error that
  stops nushell at start. It also names two keybindings `atuin`, which
  nushell 0.116 warns about on every start. The releases that call `job spawn`
  up to 18.12.1 emit `-t`; 18.13.0 to 18.13.2 emit `-d`; 18.13.3 and newer drop
  the tag; older ones, such as Debian's 18.6.1, never call it. 18.24.6
  parses and starts without warnings under nushell 0.116.1. Only the Fedora
  recipe exists, and only Fedora uses depot's build:
  - Arch ships atuin 18.24.6 itself.
  - Debian 13 ships 18.6.1 (Debian's package index). depot's apt pin is below
    Debian's packages, so a machine installs Debian's atuin of the same name
    over depot's (CI's install test did, 2026-11-10); a first draft had a
    Debian recipe, and that test failed. Debian's 18.6.1 does not call
    `job spawn`, and works with nushell 0.116.1 but warns twice on every
    start (a deprecated flag, and the same duplicate keybinding name).
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
- **Build:** none. The recipe unpacks the archive and installs the binary as
  it is, with no network access beyond the pinned download.
- **Upstream change read:** this is the package's first entry, so the baseline
  is the previous release: the diff `v18.24.5...v18.24.6` (28 commits, about
  100 files). Not read: the rest of the code base. The attestation ties the
  binary to the tagged source and upstream's workflow; it does not say the
  source is benign.
  - Build and CI: no change under `.github/`, `dist-workspace.toml`, scripts or
    a Dockerfile. `crates/atuin-octavo/build.rs` gains one `type_attribute`
    call (a clippy allow on a generated enum). No binary or vendored blobs were added: new files are Rust, SQL and
    protobuf sources.
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
  units, no links, which `check_package` enforces. `CHANGELOG.md` is left out.
  `atuin-server` is a separate archive and is not packaged. Built and
  installed in a clean `fedora:44` container on 2026-11-10, and `test.sh`
  passes: the binary runs, and `atuin init nu` output passes `nu-check`.
  It starts cleanly under nushell 0.116.1, with no `job spawn -t` and no
  warnings. **Upgrading from an older atuin is one-way for the local
  database:** 18.24.6 migrates an 18.12.1 database in place, and 18.12.1 then
  fails with `migration 20260224000100 was previously applied but is missing`
  (tried 2026-11-10). To roll back to an older atuin, move
  `~/.local/share/atuin/*.db` aside (sync again if logged in).
- **Network behavior:** `sync_address` defaults to Atuin's hosted server and
  `update_check` is on by default (a version query); both are user
  configuration. The self-updater, `atuin update`, refuses to run without the receipt that
  upstream's installer script writes, and tells the user to update through
  their package manager, so an install from depot will not replace itself
  (`crates/atuin/src/command/client/update.rs` at the tag).
- **Upstream status:** active, same organization, several releases a month.
- **Reviewed by:** Claude (Sonnet 5.5) for Daniel, 2026-11-10.
