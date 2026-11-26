# afsr: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 2.2.0-1 (2026-11-26)

- **Why depot ships it:** unchanged from 2.1.1. The Pixel OTA patcher runs
  `afsr unpack` and `afsr pack` on Daniel's server, in a Fedora toolbox, and
  the Arch machine uses the same binary.
- **Change:** upstream's 2.2.0, one release on from 2.1.1. The recipes change
  only the version, the source URL and the sha256 (Arch and rpm); `test.sh`
  and `package.env`'s other fields are untouched.
- **Source:** upstream's x86-64 Linux release asset
  `https://github.com/chenxiaolong/afsr/releases/download/v2.2.0/afsr-2.2.0-x86_64-unknown-linux-gnu.zip`,
  sha256 `541591ebcc993d21a013ccec089e7da7114c094947cfa885967d66c610896a9c`.
  The archive I downloaded has that hash and holds one file, `afsr`.
- **Attestation:** release `v2.2.0` is immutable, and
  `gh release verify-asset v2.2.0 afsr.zip -R chenxiaolong/afsr` verified
  GitHub's release attestation for this file against tag commit
  `6216774702ef14ad30d10192cb106f8ce51050c2`. `attest=release` is unchanged,
  so `lint.sh` checks it on every run. As with `avbroot` and `custota-tool`,
  it proves the file is the asset upstream published with the tag, not that
  CI built it from the tag. The tag is annotated; its commit is authored by
  Andrew Gunnerson and reported by GitHub as verified. Upstream also signs
  each asset with its SSH key (`.sig`); depot does not check that.
- **Binary:** static-pie, x86-64, stripped, no interpreter or shared
  libraries; its strings carry `2.2.0`. Not run here (the audit does not
  execute upstream code); `test.sh` checks `--version` after a clean install.
- **Build and dependencies (upstream's, not depot's):** `ci.yml` builds with
  `cargo android build` (chenxiaolong's `cargo-android`, pinned at tag
  `v0.1.6`) without `--locked`, as before; `release.yml` is unchanged and
  only drafts the release. `Cargo.lock` pins 113 packages, 111 of them from
  crates.io, and this release moves `jiff` 0.2.39 to 1.0.3 and
  `winnow-args` 0.6.1 to 0.6.5 (the publisher Daniel approved for `avbroot`
  3.39.1), and drops `defmt` and `thiserror`. No dependency comes from
  anywhere but crates.io, and no new publisher appears. The two git
  submodules move from the author's fork to the official upstream projects:
  `external/erofs-utils` is now `https://github.com/erofs/erofs-utils` at
  commit `7e52cbffa83f9eb10bbf110cb12d503a048081` (was the author's fork),
  and `external/lz4` is now `https://github.com/lz4/lz4` at v1.11.1 (was
  AOSP's fork); `external/e2fsprogs` still comes from AOSP. Both are the
  projects themselves, pinned by submodule commit. `build.rs` adds compile
  flags and source files for those newer trees (`sysmacros_wrapper.c`, the
  Windows `regex.h` stub, `manifest.c`, `windows_compat.c`) and fetches
  nothing at build time. `build.rs` still runs bindgen and `cc` over the
  three submodules.
- **Upstream code read:** I read the `v2.1.1...v2.2.0` compare, 5 commits
  and 19 files, as patches rather than the changelog. The Rust change is
  type plumbing: `LINUX_S_IF*` becomes `S_IF*` and `linux_major`/`linux_minor`
  take `dev_t`, with no new host, credential path or process spawn. The rest
  is the submodule bump, the matching `build.rs` flags, a `wrapper_erofs.h`
  include path change, and tests (`tests/roundtrip.py` only drives the built
  binary through `subprocess`, no network). `ci.yml` adds
  `qemu-user-binfmt` for the Android targets and a roundtrip test step; it
  adds no download to the release build. No telemetry, obfuscated or
  vendored blob, or `curl | sh` appears in the diff.
- **Install:** `/usr/bin/afsr` only. No install script, unit or trigger; no
  `allow` file, and the package needs no relation or override.
- **Upstream status:** active, owner `chenxiaolong`, not archived; 2.2.0
  published 2026-11-26. The release process is unchanged.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-26.

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
