# difftastic: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.72.0-1 (2026-11-03)

- **Why depot ships it:** factory's shared tool list has difftastic; Arch
  and Fedora 44 ship it, Debian 13 does not.
- **Source:** upstream tag tarball
  `https://github.com/Wilfred/difftastic/archive/refs/tags/0.72.0.tar.gz`,
  sha256 `ed8e2d59d44d62289b17c9d241e469bd72565fadf13c260676fc7a23bc28a844`.
  The author's own repository.
- **Starting recipe:** written for depot, after Arch's official PKGBUILD
  (`cargo build --frozen --release`).
- **Build:** `cargo build --locked --release` with Debian's Rust (1.85, the
  `rust-version` upstream declares) and Debian's hardening flags. Crates
  come from crates.io, pinned by upstream's `Cargo.lock` (174 entries).
- **Upstream code read:** `build.rs` compiles two vendored tree-sitter
  parsers (C sources in `vendored_parsers/`, the generated `parser.c` files
  that tree-sitter grammars ship) with `cc`, and runs `git` only when a
  `.git` directory exists (it does not in the tarball). The other parsers
  come as crates. No network at run time.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/difft`, `difft.1` and its docs. `check_package` enforces this on
  the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
