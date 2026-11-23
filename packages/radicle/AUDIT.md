# radicle: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 1.10.3-1 (2026-11-24)

- **Why depot ships it:** Radicle, the peer-to-peer code hosting stack on
  Git (`rad`, `radicle-node`, `git-remote-rad`). Arch ships it in `extra`,
  Fedora 44 does not, and no machine uses the Debian target, so this is
  `fedora-44` only.
- **Source:** upstream's source tarball from its own files server,
  `https://files.radicle.dev/releases/1.10.3/heartwood-1.10.3.tar.gz`,
  sha256 `011bd76d05328438f6c53a06f8952f1ef03fb4dc9ad47adb00190361cd1fd364`
  (the same file is served from `releases/latest/`). It unpacks with no
  top-level directory, hence `source_strip=0`. 1.10.3 is the newest stable
  release on 2026-11-24; `releases/latest/radicle.json` names it, with
  commit `7e1cb406bb935c3de008d2171e8961f57b4336ea`.
- **How the tarball was verified:** upstream signs its release binaries
  (`.sig`, SSH signatures) but not the source tarball, so it was checked
  against upstream's signed git tag instead:
  - The repository is `rad:z3gqcJUoA1n9HaHKufZs5FCSGazv5`, fetched over HTTPS
    from the seed `https://seed.radicle.dev`. The RID decodes to blob
    `c0dc26955e1b6db81f1252205bdd7d4133365882`, which is the
    `embeds/radicle.json` of the root identity commit `666cbd6f`, so the
    identity history fetched belongs to that RID.
  - The current identity document (`refs/rad/id`, 24 revisions, project
    `heartwood`) has three delegates, threshold 1. Decoded to SSH keys:
    `z6MkireRat...` is `SHA256:vV38nW5eSWfTMITdAoMCBOFzEEr0bDMXjSWHpwrpsKY`
    and `z6MksFqXN3...` is `SHA256:iTDjRHSIaoL8dpHbQ0mv+y0IQqPufGl2hQwk4TbXFlw`,
    the two release signers listed on `https://radicle.dev/download`;
    `z6MkkPvBfj...` is `SHA256:xX6bpr+AeF5G0wIvU8nLisgYRM6XjQVNJs3hkMGt+T0`.
  - Tag `releases/1.10.3` is the annotated tag object
    `d131304e52b8b8822707027fd9aca92e7fdb4cd7`, the same object in the
    canonical `refs/tags` and in the namespaces of delegates `z6MkireRat...`
    and `z6MkkPvBfj...`. `git verify-tag` reports a good SSH signature by
    `SHA256:xX6bpr...`, delegate `z6MkkPvBfj...`. It points to commit
    `7e1cb406`, the commit `radicle.json` names.
  - `git archive` of that commit, unpacked, is identical to the unpacked
    tarball (`diff -r`, no differences).
  - Not checked: the signatures on each identity revision between the root
    and the current document. The delegate set was read from the document the
    seed serves.
- **Starting recipe:** written for depot, after reading Arch's PKGBUILD
  (`archlinux/packaging/packages/radicle`, 1.10.3-1, maintainer kpcyrd).
  Taken from it: the three `-p` crates with `--bins`, `RADICLE_VERSION`,
  `LIBGIT2_NO_VENDOR=1`, and asciidoctor for the man pages. Left out: its
  git source (depot pins a tarball by sha256), the systemd units, sysusers
  and tmpfiles files (factory supplies the user unit), the shell completions
  (outside depot's allowed paths), and `cargo test` (Arch skips three flaky
  tests; the suite starts nodes and is slow, and depot recipes such as
  starship do not run it).
- **Build:** `cargo build --locked --release --bins -p radicle-cli -p
  radicle-node -p radicle-remote-helper` with Fedora's `%{build_rustflags}`
  and `%set_build_flags` (hardening and PIE for the C code built by crates),
  default features (`tor`, `i2p` address support, `systemd` socket
  activation, `structured-logger`, `backtrace`). Crates come from crates.io
  only, pinned by upstream's `Cargo.lock` (517 packages; no git or other
  registry sources). `rust-toolchain.toml` asks for 1.98.0, which only rustup
  reads; Fedora 44's rustc is 1.100.0 and the workspace's `rust-version` is
  1.88.0. libgit2 is Fedora's (1.9.7, through `pkgconfig(libgit2)`; the
  locked `libgit2-sys` is `0.18.4+1.9.3`), not the vendored copy, so
  Fedora's libgit2 fixes apply and rpm records the soname. SQLite is the copy
  bundled by the `sqlite3-src` crate (upstream enables `bundled`), pinned by
  `Cargo.lock`.
- **Man pages:** `asciidoctor --doctype manpage` on the five `*.1.adoc` files
  at the top of the tree (`rad`, `rad-id`, `rad-patch`, `radicle-node`,
  `git-remote-rad`). Upstream's `scripts/build-man-pages.sh` runs the same
  command, but installs asciidoctor through apt or pacman if it is missing,
  so the spec runs asciidoctor directly from `BuildRequires` instead.
- **Upstream code read:** the one `build.rs` (the three crates symlink to
  the top-level file) sets `RADICLE_VERSION`, `GIT_HEAD` and
  `SOURCE_DATE_EPOCH` from the environment, or asks `git` when they are
  unset; no network. The spec sets `RADICLE_VERSION` and `GIT_HEAD=unknown`
  (the tarball is not a git repository and does not carry the commit), so
  `rad --version` prints `rad 1.10.3 (unknown)`. The tree has a vendored
  `build/macos-sdk-11.3.tar.xz`, used only by upstream's container build of
  macOS binaries (`build/Dockerfile`); the Linux cargo build does not read
  it. No other binary blobs. At run time `radicle-node` connects to seeds and
  peers over the network, as configured; `rad` talks to the local node and
  runs `git`.
- **Install:** no install scripts, no units, sysusers or tmpfiles. Files:
  `/usr/bin/rad`, `/usr/bin/radicle-node`, `/usr/bin/git-remote-rad`, man
  pages under `/usr/share/man/man1`, and docs and licenses under
  `/usr/share/{doc,licenses}/radicle`. `check_package` enforces this on the
  built package. The spec adds `Requires: git-core`: `rad auth` stops with
  "A Git installation is required" without it (found by the install test),
  and `git-remote-rad` is a git remote helper. The other dependencies are
  rpm's generated sonames (glibc, libgcc, `libgit2.so.1.9`).
- **Upstream status:** active; the 1.10 series has had three point releases
  since 1.10.0. Releases are tagged `releases/<version>` by repository
  delegates and published with signed binaries on `files.radicle.dev`. The
  project's domain moved from `radicle.xyz` to `radicle.dev`
  (`files.radicle.xyz` redirects there); the files server, seed, RID and
  release signing keys are the same project's, and the repository has not
  changed hands or been archived.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-24.
