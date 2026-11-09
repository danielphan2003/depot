# dpibreak: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.6.2-1, fedora-44 (2026-11-09)

- **Why:** the always-on Fedora Atomic server needs the same circumvention
  as the Arch desktop: its ISP's filtering resets connections to some HTTPS
  hostnames, and dpibreak's default mode gets through.
- **Source and version:** unchanged, the 0.6.2 tag tarball with the same
  sha256 as the Arch recipe. The version stays in step with
  `package.env`.
- **Recipe:** written for depot on the model of `railway-cli` and
  `starship`: `cargo build --locked --release` with Fedora's Rust flags.
  `Cargo.lock` has 108 sourced entries, all `registry+crates.io`, no git
  dependencies. `Cargo.toml` asks for Rust 1.88 and edition 2024. The
  tag tarball does not carry the rendered man page; `build.rs` writes
  `dpibreak.1` into the source directory from `dpibreak.1.in` and
  `src/opt.rs`, and the spec installs that.
- **Install:** `/usr/bin/dpibreak`, the man page, the README and
  `COPYING`. No scriptlets, no unit, no capabilities, no setuid. The
  machine's own unit runs it as root (it needs `CAP_NET_ADMIN` for the
  nftables rules and the NFQUEUE). `Requires: nftables` because it shells
  out to `nft`.
- **Run-time behaviour checked:** with upstream's signed musl release
  binary (checksum matched `sha256sum.txt`) a default run added one
  nftables table, `inet dpibreak`, and removed it on SIGTERM. Ordinary
  HTTPS (Google, GitHub, depot) and the tailnet were unaffected while it
  ran. It handles TLS only: plain HTTP and QUIC are untouched.
- **Reviewed by:** Claude (Sonnet 5.5) for Daniel, 2026-11-09.

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
