# starship: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 1.27.0-1 (2026-11-03)

- **Why depot ships it:** the shell prompt in factory's shared
  configuration; Arch and Debian 13 ship it, Fedora 44 does not.
- **Source:** upstream tag tarball
  `https://github.com/starship/starship/archive/refs/tags/v1.27.0.tar.gz`,
  sha256 `f1887ffa88a7ba437d2932501794047e28d03387996f7d1c364631c053cffc44`.
  The project's own organization.
- **Starting recipe:** written for depot.
- **Build:** `cargo build --locked --release` with the default features
  (`battery`, `notify`) and Fedora's `%{build_rustflags}`. Crates come from
  crates.io, pinned by upstream's `Cargo.lock` (418 entries).
- **Upstream code read:** `build.rs` runs `shadow-rs` (build metadata from
  the environment) and embeds the preset TOML files in
  `docs/public/presets/toml`; no network. At run time starship runs the
  tools whose versions it shows (`git`, `node`, ...), as configured.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/starship` and its docs. `check_package` enforces this on the
  built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
