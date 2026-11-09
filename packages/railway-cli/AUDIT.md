# railway-cli: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

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
