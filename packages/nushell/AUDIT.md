# nushell: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.117.0-1 (2026-11-13)

- **Why depot ships it:** Daniel wants Nushell on every machine. Arch ships
  it, Debian 13 does not, and Fedora 44's version is too old for his config.
- **Why a binary:** Debian 13's Rust is too old for Nushell 0.117.0, and
  building from source is not part of this package. depot repackages the
  upstream x86-64 Linux release asset from `nushell/nushell`.
- **Source:**
  `https://github.com/nushell/nushell/releases/download/0.117.0/nu-0.117.0-x86_64-unknown-linux-gnu.tar.gz`,
  sha256 `33b907da92b0e80bd10fea9fa0e8a1624cabfebd89ee2568e365da3c492ffc68`.
  I downloaded the archive and its hash matches both the recipe and the
  upstream `SHA256SUMS` entry. The release has no checksum signature or
  GitHub attestation, so `package.env` has no `attest=` entry. `SHA256SUMS` is
  the available upstream check.
- **Starting recipe:** the PR updates the version, source URL, and sha256 in
  `package.env`, plus the RPM version and both package changelogs. It changes
  no build or install commands.
- **Build and dependencies:** depot does not build the binary. Upstream's
  release script runs `cargo build --release --workspace` without
  `--locked` or `--frozen`, and generates a lockfile if one is missing.
  **No:** the upstream release build does not refuse lockfile changes.
  The new direct workspace dependencies are `ansiopt` 0.4.0 (Darren
  Schroeder, `fdncred`), `jiff` 0.2.23 (Andrew Gallant, `BurntSushi`),
  `parse_datetime` 0.16.0 (Sylvestre Ledru, `sylvestre`), and `rustc-hash`
  2.1.2 (Nora, `Noratrieb`). The lockfile adds 16 package/version records.
  Crates.io lists `ansiopt` under Darren Schroeder (`fdncred`),
  `chrono-tz-build` and `parse-zoneinfo` under Dirkjan Ochtman (`djc`),
  `uncased` under Sergio Benitez, `vt100` under Jesse Luehrs (`doy`),
  `rand_pcg` under Diggory Hardy, and the `phf` crates under Yuki Okushi
  (`JohnTitor`). Updated package records include `html5ever` (Simon Sapin),
  `lru` (Jerome Froelich), `vte` (Christian Duerr), and `web_atoms` (Josh
  Bowman-Matthews). The new `ansiopt` publisher is not the existing `ansi-str`
  publisher and needs Daniel's approval.
- **Upstream code read:** I compared the actual `0.116.1...0.117.0` tags.
  The PR body link uses nonexistent `v`-prefixed tags. The diff changes the
  parser, completion engine, external command handling, and Nuon formatting.
  It adds no obfuscated code or vendored executable. I found no telemetry or
  automatic network check. The existing `version check` command now reads
  `GH_TOKEN` or `GITHUB_TOKEN` and sends it as a bearer token only to the
  fixed GitHub release API endpoints; the command remains explicit and retries
  without a token after a 401. The existing MCP server remains opt-in at
  runtime. Its default HTTP bind is `127.0.0.1:8080`, with loopback-only Host
  validation; Origin validation remains disabled unless configured. The CI
  workflow was restructured and updates pinned actions. The release workflow
  updates `setup-nu` and warning handling; the release script is unchanged.
  That script downloads cross-toolchains for some targets and `less` for
  Windows. It does not generate source code from those downloads.
- **Install:** no install script, maintainer script, or trigger. Both recipes
  install only `nu` under `/usr/bin` and documentation and a license under
  `/usr/share`; no `allow` entry or new install path is needed. The release
  archive also contains plugin binaries, which the recipes do not install.
- **Upstream status:** active and not archived, with the same `nushell`
  organization. Release 0.117.0 was published on 2026-11-10. The release
  process still publishes the binary archives and an unsigned `SHA256SUMS`.
- **Review status:** held for Daniel. Upstream CI does not lock dependency
  changes, and the update introduces dependencies from new publishers,
  including `fdncred`, `SergioBenitez`, and `doy`.
- **Reviewed by:** GPT-6 Luna for Daniel, 2026-11-13.

## 0.116.1-1 (2026-11-06)

- **Why depot ships it:** Daniel wants nushell on every machine; Arch ships it, Debian 13 does not, and Fedora 44's is too old.
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release binaries, and build from source only when that is needed. Debian 13 has Rust 1.85, and nushell 0.116 needs 1.96.1; Fedora 44 ships nushell 0.99.1, 17 releases behind the Arch package that `bridge` runs (0.116.1), so Daniel's `config.nu` would not load there.
- **Source:** `nu-0.116.1-x86_64-unknown-linux-gnu.tar.gz` from the GitHub release of `nushell/nushell` (the project's own organization). Its sha256 `d6d8ace4be491ed8abba4026e73b60c0470b4671d7039307e7d772282ef863da` matches the release's `SHA256SUMS` (unsigned; the release is made by upstream's release workflow). The gnu build links glibc dynamically.
- **Build:** none. The recipes unpack the archive and install the files as they are, with no network access beyond the pinned download.
- **Install:** no install script, no units, no links: plain files under `/usr/bin` and docs. `check_package` enforces this on the built package. Neither recipe strips the binary or adds build-id links. Only `nu`; the bundled plugins (`nu_plugin_*`) are left out, since nothing uses them.
- **On every bump:** check the new archive's sha256 against upstream's checksum file (and its signature, where upstream signs it) before adding the entry; `bump.sh` only records what it downloaded.
- **Upstream status:** active, same organization, release cadence unchanged.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-06.
