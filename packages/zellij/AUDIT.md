# zellij: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.46.0-1 (2026-11-13)

- **Why depot ships it:** Daniel's nushell starts inside zellij; Arch ships it, Debian 13 and Fedora 44 do not.
- **Why a binary:** Daniel's standing decision is to repackage upstream's release binaries, and build from source only when needed. Debian 13 has Rust 1.85 while zellij 0.46 requires 1.95, and Fedora 44 does not ship zellij. Upstream publishes a static musl build.
- **Source:** `zellij-x86_64-unknown-linux-musl.tar.gz` from the HTTPS GitHub release of `zellij-org/zellij`. The archive's pinned sha256 in `package.env`, `a8ee599eb357b6142443c91506a4ece3aa8811cb75dcf2b28d194bd66853c79d`, matches GitHub's v0.46.0 release asset digest. Upstream's `zellij-x86_64-unknown-linux-musl.sha256sum` covers the binary inside; its `afb6bfb5f9fdc3d9e9d094ce21866bc99d37073a5fbe75bb612e21fc9b96033d` matches the binary streamed from the archive. The tag is unsigned, and I found no detached signature or GitHub artifact attestation; the checksum file is not signed.
- **Dependencies:** Depot adds no build dependencies. The recipe does not resolve crates or other dependencies. Upstream's source adds Cargo dependencies for its desktop terminal and pins them in `Cargo.lock` from crates.io; the depot recipe repackages the release binary rather than building those sources.
- **Build:** none in depot. The Debian and RPM recipes unpack the pinned archive and install the upstream binary as-is; there are no extra downloads, compiler flags, or generated source in the depot build.
- **Install:** no install scripts, units, links, or special permissions. The recipes install the plain executable at `/usr/bin/zellij`; Debian's documentation files are also plain files in the allowed documentation directory. No new install path or `allow` exception is needed.
- **Upstream change:** Read the linked `v0.45.1...v0.46.0` diff, including its build/workflow changes. It adds the desktop terminal, inbox/attention features, configuration UI and fixes. The changed `.wasm` built-in plugins are generated from their in-repository Rust plugin sources by upstream's xtask. New desktop-terminal font files are identifiable Iosevka, Noto and Nerd Fonts assets with accompanying license texts; the added manual regeneration script fetches those assets from their named publishers over HTTPS, but it is not used by depot's recipe. The release workflow now downloads protoc 23.4 from the official Protocol Buffers GitHub release; this is upstream CI only. The new integrations reference is a link opened only when the user clicks it. No telemetry or automatic reporting was found. A new `dangerously_allow_web_serving_without_a_certificate` option permits remote plain HTTP only when explicitly enabled; it defaults off, tests keep remote HTTP refused by default, and the server warns that login tokens are unencrypted when enabled.
- **Upstream status:** active, same `zellij-org` project; v0.46.0 was published 2026-11-11.
- **Reviewed by:** GPT-6 Luna for Daniel, 2026-11-13.

## 0.45.1-1 (2026-11-06)

- **Why depot ships it:** Daniel's nushell starts inside zellij; Arch ships it, Debian 13 and Fedora 44 do not.
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release binaries, and build from source only when that is needed. Debian 13 has Rust 1.85, zellij 0.45 needs 1.95, and Fedora 44 does not ship zellij. Upstream publishes a static musl build only.
- **Source:** `zellij-x86_64-unknown-linux-musl.tar.gz` from the GitHub release of `zellij-org/zellij`. The release's `.sha256sum` file covers the binary inside the tarball, `d006c521dcb475a6005d741e9dd7c5758e5a23b28dd60a5c10cebfa4876319dd`, which matches; the tarball's sha256 is pinned in `package.env`. The binary is static, and the archive holds it at its top level, hence `source_strip=0` (lint now allows 0).
- **Build:** none. The recipes unpack the archive and install the files as they are, with no network access beyond the pinned download.
- **Install:** no install script, no units, no links: plain files under `/usr/bin` and docs. `check_package` enforces this on the built package. Neither recipe strips the binary or adds build-id links. Only `zellij`.
- **On every bump:** check the new archive's sha256 against upstream's checksum file (and its signature, where upstream signs it) before adding the entry; `bump.sh` only records what it downloaded.
- **Upstream status:** active, same organization.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-06.
