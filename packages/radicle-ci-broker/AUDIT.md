# radicle-ci-broker: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.32.1-1 (2026-11-24)

- **Why depot ships it:** Radicle CI broker (`cib`, `cibtool`) runs CI for
  repositories on a Radicle node through adapters. Daniel approved it on
  2026-11-24 for the factory CI node. Neither Fedora 44 nor its package
  search has `radicle-ci-broker` (checked
  `https://packages.fedoraproject.org/pkgs/radicle-ci-broker/`, 404), and no
  machine uses the Debian target, so this is `fedora-44` only.
- **Source:** the crates.io release `radicle-ci-broker` 0.32.1,
  `https://static.crates.io/crates/radicle-ci-broker/radicle-ci-broker-0.32.1.crate`,
  sha256 `bb6fa65f082a43515317c4658c678589521880e062547d6ed66e6b7d83488492`,
  published by `larswirzenius` on 2026-09-02 (`published_by` carries
  `github_username_matches: true`; the crate lists the same person as author
  and owner). It is `max_stable_version` on crates.io on 2026-11-24.
  Upstream publishes no release tarball: the project lives on Radicle at
  `rad:zwTxygwuz5LDGBq255RA2CbNGrz8` (the `repository` field; its node is
  `radicle.liw.fi`), whose HTTP seed serves git only, and the `/archive/...`
  endpoints answer 404. `RELEASE.md` makes `cargo publish` the release step,
  next to a `.deb` for the Radicle APT repository, so the crate is upstream's
  own release artifact and not a mirror.
- **How the crate was verified:** upstream also tags each release, with a
  PGP-signed annotated tag, so the crate was checked against the tag rather
  than trusted on its own:
  - The repository was fetched over HTTPS from its own seed,
    `https://radicle.liw.fi/zwTxygwuz5LDGBq255RA2CbNGrz8`, and its tags from
    the identity namespace
    `z6MkgEMYod7Hxfy9qCvDv5hYHkZ4ciWmLFgfvm3Wn1b2w2FV`.
  - Tag `v0.32.1` is the annotated tag object `8c27192b`, tagged by Lars
    Wirzenius, with a good PGP signature by key
    `DFB74B3C61F48BB5BAF90C826766716690EC0D85` (primary
    `EA0B7399ECCF9282A74EF8F831DA8032081D901D`). The key came from
    `keys.openpgp.org`; it is verified as belonging to `liw@liw.fi` there,
    but has no local trust path, so the signature shows as good and
    uncertified.
  - The tag points to commit `8ac2f7728d7b5aedd1b128927c63c0216653d194`,
    exactly the `sha1` in the crate's `.cargo_vcs_info.json`.
  - `git archive` of that tag, unpacked, differs from the unpacked crate in
    only four ways, all from `cargo package`: the tag's `adapterlib/` is
    missing (it is published separately as the `radicle-ci-adapter` 0.1.1
    crate, which is identical to `adapterlib/` apart from cargo's own
    normalisation, sha256
    `6f0a73c642801805b86b61c87f3f19e9dd04b0d49ec7b10b037a7f4279a4b80d`),
    `Cargo.toml` is rewritten, `Cargo.toml.orig` and `.cargo_vcs_info.json`
    are added, and the lock's adapter entry becomes a registry dependency on
    the same version 0.1.1. Every other file is byte-identical.
- **Starting recipe:** written for depot. Upstream's Debian packaging is the
  model for what to install: `debian/rules` runs `cargo install --offline
  --locked --path=. --bin cib --bin cibtool`, and `cib.1` and `cibtool.1`
  are pre-built in the tree, so the spec installs exactly those two binaries
  and two man pages. Left out: the crate's other two binaries,
  `default_branch` and `synthetic-events` (debugging helpers upstream does
  not install); `install-ci.sh` and the Ansible role (they install a node,
  Caddy and Ambient and write system units, which factory does not want from
  a package); upstream ships no shell completions.
- **Build:** `cargo build --locked --release --bin cib --bin cibtool` with
  Fedora's `%{build_rustflags}` and `%set_build_flags` (hardening and PIE for
  the C code the build compiles), default features. Crates come from
  crates.io only: `Cargo.lock` pins 404 packages, all with the crates.io
  registry as source (no git or other registries), and `--locked` refuses to
  move them. `rust-toolchain` is absent; the crate's `rust-version` is 1.90,
  and Fedora 44's rustc is 1.100.0. libgit2 is Fedora's (through
  `pkgconfig(libgit2)`, `LIBGIT2_NO_VENDOR=1`), so Fedora's fixes apply and
  rpm records the soname; the locked `libgit2-sys` is `0.18.5+1.9.4`, which
  accepts Fedora's 1.9.7. zlib is Fedora's too. SQLite is compiled from the
  copy bundled in `sqlite3-src` 0.7.0, pinned by `Cargo.lock`, because the
  `sqlite` crate 0.37.0 asks for the bundled source.
- **Upstream code read:** the single `build.rs` runs `git rev-parse --short
  HEAD` and falls back to `unknown`; it downloads nothing. The crate carries
  no git checkout, so `cib --version` prints `cib 0.32.1@unknown`; the spec
  leaves it that way rather than faking a commit. The build pulls in the
  usual published proc-macro crates (`serde_derive`, `clap_derive`,
  `thiserror-impl`, `subplotlib-derive`, `time-macros` and the like), none of
  them unusual. `ci-broker.db` is a 3 MB SQLite fixture for the acceptance
  tests in `ci-broker.subplot`, `.ambient/dch` is a shell script, and
  `ci-broker.md` is generated from the subplot document; none of them is
  installed and none is a binary blob.
  At run time `cib` reads events from the local node over its Unix control
  socket (`radicle::Profile::socket_from_env`), opens its own SQLite database
  and runs the adapters named in its configuration as subprocesses with a
  timeout; it opens no listening socket and sends no telemetry. The current
  release already contains the fix for sensitive environment variable values
  leaking into logs (commit `c7666c3`, in `src/sensitive.rs`, NEWS for
  0.31.2) and the split of the adapter helper library into
  `radicle-ci-adapter` (0.32.0).
- **Dependencies:** this is the first recipe, so there is no previous set to
  compare with. Direct dependencies are all on crates.io: the Radicle
  project's crates `radicle`, `radicle-surf` and `radicle-crypto` (published
  by FintanH and lorenzleutgeb), `radicle-job` (FintanH and larswirzenius),
  `radicle-ci-adapter` (larswirzenius), `html-page` and `subplotlib`
  (larswirzenius), `serde_norway` (cafkafk), plus clap, regex, rss, sqlite,
  tracing and the rest. The largest transitive pieces are `radicle` and
  `radicle-surf` with their `git2`, `tar` and `flate2`, the bundled SQLite of
  `sqlite3-src`, and the cryptography crates under `radicle-crypto`.
- **Install:** no install scripts, no triggers, no units, sysusers, tmpfiles,
  udev or polkit files. Files: `/usr/bin/cib`, `/usr/bin/cibtool`, man pages
  under `/usr/share/man/man1`, and docs and licenses under
  `/usr/share/{doc,licenses}/radicle-ci-broker`. `check_package` enforces
  this on the built package. The only declared relation is `Requires:
  git-core`, following upstream's Debian `Depends: git`; the broker hands
  jobs to adapters that use git. The remaining dependencies are rpm's
  generated sonames (glibc, libgcc, `libgit2.so.1.9`).
- **Upstream status:** active. 42 crates.io releases since 2024-04-03, the
  newest on 2026-09-02, and the `v0.32.1` tag is signed by the same author.
  crates.io lists 0.32.1 and then 0.31.0 (2026-08-11); the tags in between,
  0.31.1 (withdrawn as premature), 0.31.2 and 0.32.0, went out as tags and
  Debian packages but were not published to crates.io, so 0.32.1 is the
  newest artifact on the release channel depot uses. The project has not
  changed hands or been archived, and the release process is still tag,
  `cargo publish`, announce.
- **Caveat for bumps:** the bump PR body links
  `${upstream}/compare/v<old>...v<new>`, which is a GitHub URL shape; this
  repository is served by Radicle, so that link does not resolve. Audit a
  bump with `git log v<old>..v<new>` against
  `https://radicle.liw.fi/zwTxygwuz5LDGBq255RA2CbNGrz8` instead.
- **Reviewed by:** an OpenCode agent (DeepSeek V4.1 Flash) for Daniel,
  2026-11-24.
