# nushell: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.116.1-1 (2026-11-06)

- **Why depot ships it:** Daniel wants nushell on every machine; Arch ships it, Debian 13 does not, and Fedora 44's is too old.
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release binaries, and build from source only when that is needed. Debian 13 has Rust 1.85, and nushell 0.116 needs 1.96.1; Fedora 44 ships nushell 0.99.1, 17 releases behind the Arch package that `bridge` runs (0.116.1), so Daniel's `config.nu` would not load there.
- **Source:** `nu-0.116.1-x86_64-unknown-linux-gnu.tar.gz` from the GitHub release of `nushell/nushell` (the project's own organization). Its sha256 `d6d8ace4be491ed8abba4026e73b60c0470b4671d7039307e7d772282ef863da` matches the release's `SHA256SUMS` (unsigned; the release is made by upstream's release workflow). The gnu build links glibc dynamically.
- **Build:** none. The recipes unpack the archive and install the files as they are, with no network access beyond the pinned download.
- **Install:** no install script, no units, no links: plain files under `/usr/bin` and docs. `check_package` enforces this on the built package. Neither recipe strips the binary or adds build-id links. Only `nu`; the bundled plugins (`nu_plugin_*`) are left out, since nothing uses them.
- **On every bump:** check the new archive's sha256 against upstream's checksum file (and its signature, where upstream signs it) before adding the entry; `bump.sh` only records what it downloaded.
- **Upstream status:** active, same organization, release cadence unchanged.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-06.
