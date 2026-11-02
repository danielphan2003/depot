# avbroot: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 3.37.1-1 (2026-11-03)

- **Why depot ships it:** patches the Pixel's OTA images for root with
  Daniel's own AVB keys (the caiman OTA setup on `bridge`). Arch does not
  package it.
- **Source:** upstream tag tarball
  `https://github.com/chenxiaolong/avbroot/archive/refs/tags/v3.37.1.tar.gz`,
  sha256 `ab97eb47c4e8bcf87886c848a98a27d832b54d0978c2b66b00e05e36d2d43082`.
  Repository and releases by its author, Andrew Gunnerson (chenxiaolong),
  who also signs the release zips with SSH keys; depot builds the tag
  instead of repackaging them.
- **Starting recipe:** AUR `avbroot` (aur.git `a8d8892`, maintainer since
  the first upload). It downloads the same tarball and runs `cargo build
  --release --locked`; no install script. depot adds the offline `--frozen`
  build and builds only the `avbroot` crate (not `xtask`, `e2e` or `fuzz`).
- **Build:** `cargo fetch --locked`, then an offline `cargo build --frozen
  --release` of `-p avbroot`. Crates come from crates.io, pinned by
  upstream's `Cargo.lock`; three entries are git dependencies pinned by
  commit (RustCrypto/formats, chenxiaolong/system-properties), which cargo
  checks out at exactly that commit. Compiler flags are the distribution's
  (makepkg's `CFLAGS`/`RUSTFLAGS`; `-ffat-lto-objects` for the C parts, as
  Arch's Rust packaging guidelines ask).
- **Upstream code read:** `build.rs` compiles the bundled `.proto` files
  with `protox` and `prost-build`, all in-process: no network, no external
  commands. 234 crates. avbroot is offline: it reads and writes local image
  files.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/avbroot`, its README and license. `check_package` enforces this
  on the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
