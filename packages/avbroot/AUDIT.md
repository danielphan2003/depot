# avbroot: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.


## 3.39.1-1, fedora-44 (2026-11-14)

- **Change:** a `fedora-44` recipe (`rpm/avbroot.spec`) so the OTA patcher
  can run in a Fedora toolbox on Daniel's server (2026-11-14). It
  repackages the same release asset, sha256 and attestation as the Arch
  recipe in 3.39.1-1 below; upstream code unchanged.
- **Install:** `/usr/bin/avbroot`, `README.md` and `LICENSE`, as on Arch. No
  `%pre`, `%post` or triggers; rpm's post-install processing is off
  (`__os_install_post`), as in `railway-cli`, so the binary is installed
  byte for byte.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-14.

## 3.39.1-1 (2026-11-13)

- **Why depot ships it:** patches the Pixel's OTA images for root with
  Daniel's own AVB keys (the caiman OTA setup on `bridge`). Arch does not
  package it.
- **Source:** upstream's x86-64 Linux release asset
  `https://github.com/chenxiaolong/avbroot/releases/download/v3.39.1/avbroot-3.39.1-x86_64-unknown-linux-gnu.zip`,
  sha256 `145378039c372a1c80f3d0df7bdbe59b4ca6f612c10949da426278bb8b9994d7`.
  The downloaded archive has that hash. `gh release verify-asset` verified
  GitHub's immutable release attestation for this exact asset and tag.
  `attest=release` is unchanged. It proves that GitHub published these bytes
  with the release, not that CI built them from the tag's source.
- **Starting recipe:** the PR keeps the same release asset and
  `attest=release`. It updates the version and sha256, and resets `pkgrel`
  from 2 to 1 for the new upstream version.
- **Binary:** static-pie x86-64, with no shared libraries or runtime
  dependencies. The release CI now targets x86-64-v2, which does not require
  AVX. The recipe still declares `x86_64`; Daniel needs to confirm that this
  CPU baseline matches depot's supported machines.
- **Build and dependencies:** depot repackages the upstream binary and does
  not build it. Upstream CI runs Cargo through `cargo-android`, which forwards
  commands to Cargo. CI downloads that helper at tag `v0.1.6` and installs
  target toolchains. `Cargo.lock` pins the crate versions and checksums, but
  CI invokes `cargo android build` without `--locked` or `--frozen`. **No:**
  the upstream build does not refuse lockfile changes. The update adds
  `winnow-args` 0.6.1, published on crates.io by Luca Barbato (`lu-zero`),
  plus `winnow-args-derive` 0.6.1 from the same publisher and
  `terminal_size` 0.4.4 from Andrew Chin (`eminence`). Daniel needs to approve
  these new dependency publishers before this update can merge.
- **Upstream code read:** I compared `v3.37.1...v3.39.1`. The diff replaces
  Clap with `winnow-args` across the CLI, updates cryptography crates, and
  recomputes boot-image SHA-1 IDs when the original ID matches the checksum.
  The changelog also describes the x86-64 baseline change and an image ID fix.
  It also removes the old RSA advisory exception after updating RSA. I found
  no new application network access, telemetry, credential export, obfuscated
  code, or vendored binary blobs. The CI workflow changes CPU flags and its
  ARM runner, and adds a `libc6-dev` reinstall to avoid amd64v3 static libraries.
  The release workflow updates its pinned `action-gh-release` version.
- **Install:** no install script, units, or triggers. The recipe still installs
  `/usr/bin/avbroot`, its README, and its license. No `allow` entry or new
  install path is needed.
- **Upstream status:** active and not archived, with the same owner,
  `chenxiaolong`. Release 3.39.1 was published on 2026-11-10. The release
  workflow changed only its pinned `action-gh-release` version.
- **Reviewed by:** GPT-6 Luna for Daniel, 2026-11-13.

## 3.37.1-2 (2026-11-09)

- **Change:** upstream's release binary instead of a source build (Daniel,
  2026-11-09: a package whose upstream binary carries a GitHub attestation
  uses that binary). The version, and so the upstream code, is the one
  audited in 3.37.1-1 below.
- **Source:**
  `https://github.com/chenxiaolong/avbroot/releases/download/v3.37.1/avbroot-3.37.1-x86_64-unknown-linux-gnu.zip`,
  sha256 `ca8e1e02bc33f5569d5228f312ce1351d0244fecd2d2163cb5a3c1a283a6e4a3`:
  `avbroot`, `README.md`, `LICENSE`.
- **Attestation:** GitHub's immutable-release attestation
  (`https://in-toto.io/attestation/release/v0.2`) lists this file, by
  sha256, as an asset of release `v3.37.1` in `chenxiaolong/avbroot`.
  `lint.sh` checks it with `gh release verify-asset` on every run. It proves
  the file is the unchanged asset upstream published with that tag. It does
  not prove upstream's CI built it from the tag's source: Daniel accepted
  that on 2026-11-09 (any GitHub attestation counts). Upstream also signs
  each asset with its SSH key (`.sig`); depot does not check that.
- **Binary:** static-pie, x86-64: no shared libraries, so no runtime
  dependencies. Upstream's own build flags.
- **Install:** `/usr/bin/avbroot`, the README and the license, as before.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-09.

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
