# dpibreak: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.6.2-1 (2026-11-03)

- **Why depot ships it:** system-wide DPI circumvention; `dpibreak.service`
  runs it on `bridge` (a hand-written unit in `/etc/systemd/system`,
  unchanged). Arch does not package it.
- **Source:** upstream tag tarball
  `https://github.com/dilluti0n/dpibreak/archive/refs/tags/v0.6.2.tar.gz`,
  sha256 `3a61d445b6f25f895cb9d5c976079e0dc7fb8d9fac592e497f9fc703df82c905`
  (the same hash the AUR pins). Upstream also publishes a signed
  `sha256sum.txt` for its musl binaries; depot builds the tag instead.
- **Starting recipe:** AUR `dpibreak` (aur.git `5cf5a22`), maintained by the
  upstream author. It runs an unlocked `cargo build --release`; depot uses
  `--locked`/`--frozen`. No install script.
- **Build:** `cargo fetch --locked`, then an offline `cargo build --frozen
  --release`. Crates come from crates.io, pinned by upstream's `Cargo.lock`.
  Compiler flags are the distribution's (makepkg's `CFLAGS`/`RUSTFLAGS`;
  `-ffat-lto-objects` for the C parts, as Arch's Rust packaging guidelines
  ask).
- **Upstream code read:** `build.rs` only fills the man page template
  `dpibreak.1.in` from `src/opt.rs` (and adds a Windows resource on
  Windows). 110 crates. At run time dpibreak needs root (it installs
  nftables rules and reads an NFQUEUE); the package grants nothing itself,
  no capabilities, no setuid: the machine's unit runs it as root.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/dpibreak`, `dpibreak.1`, its README and license. `check_package`
  enforces this on the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
