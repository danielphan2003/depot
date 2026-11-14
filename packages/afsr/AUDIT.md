# afsr: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 2.1.1-1 (2026-11-14)

- **Why depot ships it:** the Pixel OTA patcher runs
  `afsr unpack` and `afsr pack` to add system apps to the `system` and
  `vendor` images. Daniel asked for the patcher to run in a Fedora toolbox on
  his server (2026-11-14). No distribution packages it; the Arch machine had
  a local `cargo install` build (1.0.4), which this replaces, so the package
  targets `arch` as well as `fedora-44`.
- **Source:** upstream's x86-64 Linux release asset
  `https://github.com/chenxiaolong/afsr/releases/download/v2.1.1/afsr-2.1.1-x86_64-unknown-linux-gnu.zip`,
  sha256 `cf442165f1c16d52f699e10f92746bdcd3353649dcaaa4d228629a9fe92dccf0`.
  It holds one file, `afsr`. The download has that hash.
- **Attestation:** release `v2.1.1` is immutable, and
  `gh release verify-asset v2.1.1 afsr-2.1.1-x86_64-unknown-linux-gnu.zip -R chenxiaolong/afsr`
  verified GitHub's release attestation for this file. `attest=release`, so
  `lint.sh` checks it on every run. As with `avbroot` and `custota-tool`, it
  proves the file is the asset upstream published with the tag, not that CI
  built it from the tag. Upstream also signs each asset with its SSH key
  (`.sig`); depot does not check that.
- **Binary:** static-pie, x86-64, stripped, no shared libraries; `afsr
  --version` prints `afsr 2.1.1`. Upstream's 2.1.1 changelog says it rebuilt
  for x86-64 CPUs without AVX, which 2.1.0 broke.
- **Build and dependencies (upstream's, not depot's):** `ci.yml` builds with
  `cargo android build` (chenxiaolong's `cargo-android`, pinned at tag
  `v0.1.6`) without `--locked`, as for `avbroot`. `release.yml` only drafts
  the release; the maintainer publishes it. `Cargo.lock` pins 119 crates,
  every one from crates.io, including `winnow-args` 0.6.1, the publisher
  Daniel approved for `avbroot` 3.39.1. `build.rs` runs bindgen and `cc` over
  three git submodules: AOSP's `platform/external/e2fsprogs` and
  `platform/external/lz4`, and the author's fork of `erofs-utils`. No
  `build.rs` download.
- **Upstream code read:** `Cargo.toml`, `build.rs`'s inputs, both workflows,
  and a search of `src/` for network and process use. No networking crate and
  no socket code. The one `Command::new` re-runs afsr itself
  (`/proc/self/exe`) to call its bundled `mke2fs` subcommand. The license is
  GPL-2.0-or-later (e2fsprogs), not GPL-3.0 like the author's other tools.
- **Install:** `/usr/bin/afsr` only. No install script, unit or trigger; no
  `allow` file.
- **Upstream status:** active, owner `chenxiaolong`; 2.1.1 published
  2026-11-10.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-14.
