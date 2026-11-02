# sd: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 1.1.0-1 (2026-11-03)

- **Why depot ships it:** factory's shared tool list has sd; Arch and Debian
  13 ship it, Fedora 44 does not.
- **Source:** upstream tag tarball
  `https://github.com/chmln/sd/archive/refs/tags/v1.1.0.tar.gz`, sha256
  `defdce484f8c92f265e1282490572575028967c2c55d356111d1e49a3ea9a88e`. The
  author's own repository.
- **Starting recipe:** written for depot.
- **Build:** `cargo build --locked --release -p sd-cli` with Fedora's
  `%{build_rustflags}` (hardening, PIE). Crates come from crates.io, pinned
  by upstream's `Cargo.lock` (106 entries). The man page is upstream's
  pregenerated `gen/sd.1`.
- **Upstream code read:** No `build.rs`; the `xtask` crate (which
  regenerates `gen/`) is not built. sd reads and writes the files it is
  given; no network.
- **Install:** no install script, no units, nothing outside `/usr/bin/sd`,
  `sd.1` and its docs. `check_package` enforces this on the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
