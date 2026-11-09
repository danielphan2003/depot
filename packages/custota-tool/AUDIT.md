# custota-tool: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 6.8-2 (2026-11-09)

- **Change:** upstream's release binary instead of a source build (Daniel,
  2026-11-09: a package whose upstream binary carries a GitHub attestation
  uses that binary). The version, and so the upstream code, is the one
  audited in 6.8-1 below.
- **Source:**
  `https://github.com/chenxiaolong/Custota/releases/download/v6.8/custota-tool-6.8-x86_64-unknown-linux-gnu.zip`,
  sha256 `7c7e6cb64f3fe0993969813d26b4a66b7ea1689af47579e6543391a55ca40ecb`:
  the `custota-tool` binary alone.
- **Attestation:** GitHub's immutable-release attestation
  (`https://in-toto.io/attestation/release/v0.2`) lists this file, by
  sha256, as an asset of release `v6.8` in `chenxiaolong/Custota`. `lint.sh`
  checks it with `gh release verify-asset` on every run. It proves the file
  is the unchanged asset upstream published with that tag. It does not prove
  upstream's CI built it from the tag's source: Daniel accepted that on
  2026-11-09 (any GitHub attestation counts). Upstream also signs each asset
  with its SSH key (`.sig`); depot does not check that.
- **Binary:** static-pie, x86-64: no shared libraries, so no runtime
  dependencies. Upstream's own build flags.
- **Install:** `/usr/bin/custota-tool` only; the zip carries no README or
  license file.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-09.

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
  the version reads `v6.8` (the tag is annotated, which `git describe`
  needs). That repository is local only; nothing is
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
