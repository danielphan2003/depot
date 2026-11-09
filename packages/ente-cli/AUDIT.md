# ente-cli: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.4.2-2 (2026-11-09)

- **Change:** upstream's release binary instead of a source build (Daniel,
  2026-11-09: a package whose upstream binary carries a GitHub attestation
  uses that binary). The version, and so the upstream code, is the one
  audited in 0.4.2-1 below.
- **Source:**
  `https://github.com/ente/ente/releases/download/ente-cli-v0.4.2/ente-cli-v0.4.2-linux-amd64.tar.gz`,
  sha256 `d1318a5bc3cf8f458f14732ea110cd167cc3e64e2d7ca5f3ce1cdd80f283b18a`:
  the `ente` binary alone.
- **Attestation:** GitHub's immutable-release attestation
  (`https://in-toto.io/attestation/release/v0.2`) lists this file, by
  sha256, as an asset of release `ente-cli-v0.4.2` in `ente/ente`. `lint.sh`
  checks it with `gh release verify-asset` on every run. It proves the file
  is the unchanged asset upstream published with that tag. It does not prove
  upstream's CI built it from the tag's source: Daniel accepted that on
  2026-11-09 (any GitHub attestation counts).
- **Binary:** static-pie, x86-64: no shared libraries. The source build
  linked the system's dbus, OpenSSL and SQLCipher; upstream's binary carries
  its own, so the package no longer depends on them, and those libraries are
  now upstream's versions, updated only by an ente release.
- **Install:** `/usr/bin/ente` only; the tarball carries no README or
  license file.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-09.

## 0.4.2-1 (2026-11-03)

- **Why depot ships it:** Ente's command-line client (exports and account
  tools); Daniel uses Ente Photos. Replaces the AUR's `ente-cli-bin`, which
  was stuck at 0.3.0 and flagged out of date.
- **Source:** upstream monorepo tag tarball
  `https://github.com/ente/ente/archive/refs/tags/ente-cli-v0.4.2.tar.gz`,
  sha256 `79758575fad414cb0e3a5e12f0d95c6e541be91ef840b5329c87df9160632e56`
  (the same hash the AUR pins). The GitHub organization was renamed from
  `ente-io` to `ente`; the old name redirects, so this is the same project,
  not a fork.
- **Starting recipe:** AUR `ente-cli` (aur.git `4c2cb5b`, Mark Wagie, an
  established AUR maintainer). Builds the `ente-cli` crate against system
  sqlcipher and openssl (`LIBSQLITE3_SYS_USE_PKG_CONFIG=1`,
  `OPENSSL_NO_VENDOR=1`); no install script. depot drops the workspace-wide
  `cargo fetch`, which would download the Tauri, mobile and wasm bindings'
  crates too, and builds with `cargo build --locked -p ente-cli --bin ente`.
- **Build:** `cargo build --locked --release -p ente-cli`. Crates come from
  crates.io, pinned by upstream's `Cargo.lock` (1121 entries for the whole
  workspace; the CLI needs a subset). Four git dependencies, pinned by
  commit, belong to Ente (`ente/heic-decoder`, `ente-io/rav1d`). Compiler
  flags are makepkg's.
- **Upstream code read:** 0.4 is a rewrite in Rust; the 0.3 Go CLI is in
  `cli/` and not built. It talks to Ente's API (`api.ente.io`) as any Ente
  client does, keeps a local SQLCipher database, and stores its vault key in
  the Secret Service keyring (or `ENTE_CLI_VAULT_KEY`). `ente help
  migration` lists what changed from 0.3; an existing `~/.ente` login may
  need signing in again.
- **Install:** no install script, no units, nothing outside `/usr/bin/ente`,
  its README and license. `check_package` enforces this on the built
  package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
