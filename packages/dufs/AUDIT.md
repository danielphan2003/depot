# dufs: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.


## 0.47.0-1, fedora-44 (2026-11-14)

- **Change:** a `fedora-44` recipe (`rpm/dufs.spec`) so Daniel's server can
  serve the OTA directory to the phone (2026-11-14). Same tag
  tarball and sha256 as the Arch recipe below; upstream code unchanged.
- **Build:** `cargo build --locked --release` with Fedora's Rust flags
  (`%{build_rustflags}`: hardening, PIE), as in `starship`. Crates come from
  crates.io during the build, pinned by upstream's `Cargo.lock`, and
  `--locked` refuses to change it.
- **Install:** `/usr/bin/dufs`, the README and both licenses. As on Arch, no
  units, config, completions, `%pre`, `%post` or triggers.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-14.

## 0.47.0-1 (2026-11-03)

- **Why depot ships it:** serves the Pixel OTA directory to the phone
  (`dufs-ota-caiman.service` on `bridge`, port 5000). Replaces the AUR's
  `dufs-bin`.
- **Source:** upstream tag tarball
  `https://github.com/sigoden/dufs/archive/refs/tags/v0.47.0.tar.gz`, sha256
  `bab9d4fa1654adc6c88523b61bb8697f575334248cf554282e1f87e2329c0569`.
  Repository and releases by its author, sigoden, unchanged since 2022.
- **Starting recipe:** AUR `dufs` (aur.git `a231524`, maintained by an Arch
  packaging bot, `lilac`). It downloads the same tarball and builds with
  `cargo build --frozen`. It also installs a system `dufs.service`,
  `dufs@.service`, a `sysusers.d` user, a `tmpfiles.d` entry and
  `/etc/dufs/config.yaml`; depot drops all of them (the machine keeps its
  own user unit) and the shell completions.
- **Build:** `cargo fetch --locked`, then an offline `cargo build --frozen
  --release` with the default `tls` feature (rustls). Crates come from
  crates.io, pinned by upstream's `Cargo.lock`. Compiler flags are the
  distribution's (makepkg's `CFLAGS`/`RUSTFLAGS`; `-ffat-lto-objects` for
  the C parts, as Arch's Rust packaging guidelines ask).
- **Upstream code read:** `build.rs`: none. The `assets/` web UI (HTML, JS,
  CSS) is upstream's own, embedded with `include_str!`. 312 crates in the
  lock file, all from crates.io. Network access is the server itself.
- **Install:** no install script, no units, nothing outside `/usr/bin/dufs`,
  its README and licenses. `check_package` enforces this on the built
  package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
