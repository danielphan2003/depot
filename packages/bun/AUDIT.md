# bun: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 1.4.5-1 (2026-11-20)

- **Change:** upstream's 1.4.5, one release on from 1.4.4. The recipes are
  unchanged apart from the version: `package.env`'s version and sha256, the
  rpm spec's `Version` and changelog, and the deb changelog. The archive name,
  `bun-linux-x64.zip`, is the same one 1.4.4 pinned, so this is still the
  regular x64 build (not `-baseline`), which needs AVX2 as before.
- **Source:** `bun-linux-x64.zip` from the GitHub release `bun-v1.4.5` of
  `oven-sh/bun`, sha256
  `94559b3b528995a49452f9f2404cec74f2efd7d06e0a000a8cd214b02c3666eb`.
  The archive I downloaded has that hash, and the line matches
  `SHASUMS256.txt` from the same release. `SHASUMS256.txt.asc` verifies with
  Robobun's key `F3DCC08A8572C0749B3E18888EAB4D40A7B22B59`, the one the
  release's `dockerhub/*/Dockerfile` files inline and pin with
  `--assert-signer`: I imported the block from
  `dockerhub/debian/Dockerfile` at the tag and `gpg --verify` passed, then
  `sha256sum -c` against the verified list passed. As before, the binary
  carries no GitHub attestation, and `package.env` names none.
- **Archive:** two entries, the `bun-linux-x64/` directory and
  `bun-linux-x64/bun` (107,394,952 bytes), the same shape as 1.4.4's.
- **Build and dependencies:** none. The recipes unpack the archive and install
  the files as they are, with no network access beyond the pinned download.
  Upstream's `package.json` only bumps its own version, so no npm dependency
  was added or moved. The sources bun bundles moved, each pinned by commit in
  `scripts/build/deps/` from its own project: BoringSSL from
  `oven-sh/boringssl` (`41bf9b5` to `fe703e9`, a bump of the fork to upstream
  `148a7b1f`), c-ares 1.34.9 from `c-ares/c-ares`, lsquic 4.11.2 from
  `litespeedtech/lsquic`, SQLite 3.54.1, llhttp 9.4.4 (byte for byte what
  Node.js 26.13.1 vendors, per its README) and zlib-ng and zstd from their own
  projects. No new dependency publisher, and nothing is fetched from a fork,
  a mirror or an author's account.
- **Upstream code read:** I compared `bun-v1.4.4...bun-v1.4.5`, 24 commits and
  92 files, reading the patches rather than the release notes. The runtime
  changes are small and all repairs:
  - Two decompression fixes. `patches/zlib/inflate-window-size.patch` checks a
    zlib header's window size before storing it, so a bad value cannot stick
    (`zlib-ng` commit `1bfa59ae1`, not in a release yet). The zstd patch
    zeroes the bytes after the decoded literals and returns on a failed
    Huffman decode before the literals are shifted. Both are upstream fixes
    carried as patches, and neither adds a download or a build step.
  - The BoringSSL fork drops its one-shot `SHA1()`/`SHA256()` entry points, so
    `src/sha_hmac/sha.rs` and the two callers (the compile cache's key hash and
    the system-certificate dedup) now use init/update/final. Same digests, no
    new code path.
  - BoringSSL's header constants moved: the QUIC TLS code's WPA3 compliance
    policy and `X509_V_FLAG_IGNORE_EXPIRED_TRUST_ANCHORS` take the fork's new
    values, and `node_quic_shim.c` now asserts every constant the Rust side
    hard-codes, so a future drift fails the build instead of silently
    changing behavior.
  - `src/js/node/http2.ts` moves one option validation earlier, with no change
    to what it accepts. `src/runtime/node/quic/endpoint.rs` corrects a comment
    about lsquic's congestion-control enum, and `h3blast` (a test tool) maps
    BBR to its new number.
  - Vendored copies refreshed: `sqlite3.c` to 3.54.1, `llhttp.c`/`llhttp.h`
    to 9.4.4, plus `sqlite3_local.h` and the HTTP parser's version strings.
  - The rest is release engineering: every `release.yml` job now runs in a
    `release` environment, npm and bun-types publish through trusted
    publishing (`id-token: write`, no `NPM_TOKEN`), macOS artifacts are signed
    by a new `sign-darwin-artifacts.ts` that imports the Developer ID into a
    throwaway keychain, `upload-release.sh` became `upload-release.ts`, and
    the Dockerfiles add `--retry-all-errors` to their checksum download.
- **Network and telemetry:** no new endpoint, telemetry payload or credential
  handling in the runtime. The URLs the diff adds are upstream's CI tooling
  (Sentry's CLI, the `gh` CLI, the AWS CLI, Apple's certificate authorities)
  and documentation links; none is reached by the installed binary.
- **Install:** unchanged. No install script, units or links: plain files under
  `/usr/bin` and docs, with `bunx` a two-line script running `bun x`. No
  `allow` entry or new install path is needed, and `test.sh` is unchanged
  (`bun --version`, an arithmetic check, and `bunx --version`).
- **Upstream status:** active and not archived, same organization `oven-sh`,
  same release workflow, which this diff only tightens (environments and
  trusted publishing). 1.4.5 was published 2026-11-19.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-20.

## 1.4.4-1 (2026-11-06)

- **Why depot ships it:** factory's agent CLIs (claude, codex, opencode) are bun globals, and `supercomputer` and instabox `t3` used `curl https://bun.sh/install | bash`, which no system update touches. Arch ships bun.
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release binaries, and build from source only when that is needed. bun cannot be built in CI within reason: it needs Zig and a WebKit/JavaScriptCore build. Neither Debian 13 nor Fedora 44 ships it.
- **Source:** `bun-linux-x64.zip` from the GitHub release `bun-v1.4.4` of `oven-sh/bun`. Its sha256 `bf8ccbfb2b0b80159e0f9a6d15c55317add8077534dbc6130a3edb52fccb395c` is in the release's `SHASUMS256.txt.asc`, whose signature verifies with Robobun's key `F3DCC08A8572C0749B3E18888EAB4D40A7B22B59` (the key upstream's own Dockerfiles import). The regular x64 build needs AVX2, which `supercomputer` and instabox `t3` have.
- **Build:** none. The recipes unpack the archive and install the files as they are, with no network access beyond the pinned download.
- **Install:** no install script, no units, no links: plain files under `/usr/bin` and docs. `check_package` enforces this on the built package. Neither recipe strips the binary or adds build-id links. `bun`, and `bunx` as a two-line script running `bun x`, because upstream's `bunx` is a link to `bun`. bun's runtime self-update (`bun upgrade`) would overwrite `/usr/bin/bun` only as root; updates come from depot instead.
- **On every bump:** check the new archive's sha256 against upstream's checksum file (and its signature, where upstream signs it) before adding the entry; `bump.sh` only records what it downloaded.
- **Upstream status:** active, same organization; release process unchanged.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-06.
