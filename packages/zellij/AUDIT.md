# zellij: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.45.1-1 (2026-11-06)

- **Why depot ships it:** Daniel's nushell starts inside zellij; Arch ships it, Debian 13 and Fedora 44 do not.
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release binaries, and build from source only when that is needed. Debian 13 has Rust 1.85, zellij 0.45 needs 1.95, and Fedora 44 does not ship zellij. Upstream publishes a static musl build only.
- **Source:** `zellij-x86_64-unknown-linux-musl.tar.gz` from the GitHub release of `zellij-org/zellij`. The release's `.sha256sum` file covers the binary inside the tarball, `d006c521dcb475a6005d741e9dd7c5758e5a23b28dd60a5c10cebfa4876319dd`, which matches; the tarball's sha256 is pinned in `package.env`. The binary is static, and the archive holds it at its top level, hence `source_strip=0` (lint now allows 0).
- **Build:** none. The recipes unpack the archive and install the files as they are, with no network access beyond the pinned download.
- **Install:** no install script, no units, no links: plain files under `/usr/bin` and docs. `check_package` enforces this on the built package. Neither recipe strips the binary or adds build-id links. Only `zellij`.
- **On every bump:** check the new archive's sha256 against upstream's checksum file (and its signature, where upstream signs it) before adding the entry; `bump.sh` only records what it downloaded.
- **Upstream status:** active, same organization.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-06.
