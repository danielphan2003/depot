# custota-tool: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 6.8-1 (2026-11-03)

- **Why depot ships it:** generates the signed update metadata the Custota
  updater on the Pixel reads (same OTA setup). Arch does not package it.
- **Source:** upstream tag tarball
  `https://github.com/chenxiaolong/Custota/archive/refs/tags/v6.8.tar.gz`,
  sha256 `f16c75e827d9bda46cb61b7f07394f45ff1019b77e398a4ded1e25725f943c1c`.
  Same author as avbroot.
- **Starting recipe:** AUR `custota-tool` (aur.git `a9584de`, `lilac`). It
  clones the git tag, because `custota-tool/build.rs` runs `git describe`
  and fails outside a git repository. depot keeps the sha256-pinned tarball
  and, in `prepare()`, makes a one-commit local repository tagged `v6.8`, so
  the version reads `v6.8`. That repository is local only; nothing is
  fetched.
- **Build:** `cargo fetch --locked`, then an offline `cargo build --frozen
  --release` of `-p custota-tool`. Crates come from crates.io, pinned by
  upstream's `Cargo.lock`; five entries are git dependencies pinned by
  commit (avbroot at tag v3.37.1, RustCrypto/formats, chenxiaolong/sepatch
  and system-properties). Compiler flags are the distribution's (makepkg's
  `CFLAGS`/`RUSTFLAGS`; `-ffat-lto-objects` for the C parts, as Arch's Rust
  packaging guidelines ask).
- **Upstream code read:** `build.rs` runs only `git rev-parse`, `git
  describe` and `git rev-list` on the source tree. `system-ca-certs/` holds
  four small text files (a Magisk module template) that the tool writes out
  when asked; they are read, not executed, at build time. The Android app in
  the same tarball (Gradle, including `gradle-wrapper.jar`) is not built.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/custota-tool`, its README and license. `check_package` enforces
  this on the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
