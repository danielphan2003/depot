# bun: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 1.4.4-1 (2026-11-06)

- **Why depot ships it:** factory's agent CLIs (claude, codex, opencode) are bun globals, and `supercomputer` and instabox `t3` used `curl https://bun.sh/install | bash`, which no system update touches. Arch ships bun.
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release binaries, and build from source only when that is needed. bun cannot be built in CI within reason: it needs Zig and a WebKit/JavaScriptCore build. Neither Debian 13 nor Fedora 44 ships it.
- **Source:** `bun-linux-x64.zip` from the GitHub release `bun-v1.4.4` of `oven-sh/bun`. Its sha256 `bf8ccbfb2b0b80159e0f9a6d15c55317add8077534dbc6130a3edb52fccb395c` is in the release's `SHASUMS256.txt.asc`, whose signature verifies with Robobun's key `F3DCC08A8572C0749B3E18888EAB4D40A7B22B59` (the key upstream's own Dockerfiles import). The regular x64 build needs AVX2, which `supercomputer` and instabox `t3` have.
- **Build:** none. The recipes unpack the archive and install the files as they are, with no network access beyond the pinned download.
- **Install:** no install script, no units, no links: plain files under `/usr/bin` and docs. `check_package` enforces this on the built package. Neither recipe strips the binary or adds build-id links. `bun`, and `bunx` as a two-line script running `bun x`, because upstream's `bunx` is a link to `bun`. bun's runtime self-update (`bun upgrade`) would overwrite `/usr/bin/bun` only as root; updates come from depot instead.
- **On every bump:** check the new archive's sha256 against upstream's checksum file (and its signature, where upstream signs it) before adding the entry; `bump.sh` only records what it downloaded.
- **Upstream status:** active, same organization; release process unchanged.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-06.
