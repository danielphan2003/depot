# ente-cli: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

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
