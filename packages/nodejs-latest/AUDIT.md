# nodejs-latest: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 26.13.1-1 (2026-11-13)

- **Why depot ships it:** Daniel wants the newest stable Node, never an alpha
  (26 now; 27 is an alpha until 2027-04-22), updated through the package
  manager, as Arch does on `bridge` (26.13.1).
- **Why a binary:** Daniel's standing decision is to repackage upstream's
  release binaries, and build from source only when that is needed. Building
  Node from source takes about an hour per target on a GitHub runner, for the
  same binary nodejs.org publishes. Fedora 44 ships Node 24 only
  (`nodejs24`), Debian 13 ships 20.
- **Source:** `node-v26.13.1-linux-x64.tar.xz` from
  `https://nodejs.org/dist/v26.13.1/`. Its sha256
  `5c063e46bab0fbc1c17cc445d7ff129cbdcd0471be6ed83b6ab864f8143bc864` is the
  line in `SHASUMS256.txt.asc` for that file. That file's signature verifies
  (`gpg --verify`: GOODSIG, VALIDSIG) with
  `5BE8A3F6C8A5C01D106C0AD820B1A390B168D356` (Antoine du Hamel), one of the
  release keys node's README lists and `nodejs/release-keys` carries. The
  26.13.0 release happened to be signed by Richard Lau's key
  `C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C`, also on that list, so the
  signer changes between releases while the checksum file covers the archive
  each time. nvchecker follows stable tags only, so no alpha or RC is
  proposed.
- **Build:** none. The recipes unpack the archive and install the files as
  they are, with no network access beyond the pinned download. The archive's
  file list is identical to 26.13.0's once the version in the top-level
  directory is normalised: same `bin/node`, `bin/npm`, `bin/npx`,
  `lib/node_modules`, `include/`, docs and man page, no new binary.
- **Dependencies:** the update adds none to the recipe. Upstream vendors and
  updates its own deps in this release (sqlite 3.54.1, undici 8.12.3 and
  8.12.4, brotli 1.2.1, llhttp 9.4.4); all are existing vendored components
  of the same project, not new publishers. `bin/node` still links only
  glibc, libstdc++, libgcc, libatomic, libdl, libm and libpthread, so the
  runtime dependency set is unchanged.
- **Install:** no install script, no units, no links: plain files under
  `/usr/bin`, `/usr/lib/nodejs-latest` and docs. `check_package` enforces
  this on the built package. Neither recipe strips the binary or adds
  build-id links. `npm` and `npx` stay two-line scripts, because upstream's
  are links. Headers are still left out; node-gyp downloads its own. No new
  path and no `allow` entry.
- **Upstream code read:** I read the `v26.13.0...v26.13.1` diff: 28 commits,
  79 files, a security release. It fixes http2 stream/write handling
  (null write request, abandoned streams, ALTSVC overflow, retained
  buffers, maxSessionMemory accounting), TLS SNI and resumption handling
  (resumption or renegotiation changing SNI, mTLS without a session id
  context, a remotely reachable server crash, CA of SNI contexts), redacts
  proxy credentials in invalid proxy URL errors, isolates `https` Agent TLS
  policy keys, stops recursive `fs.watch` leaking denied descendants, and
  handles zlib params callbacks after destroy. It also updates vendored deps
  and Nix tooling. No new network access, telemetry, install rule, or
  release-process change beyond the usual signed `SHASUMS256.txt`.
- **Upstream status:** active and not archived, still the `nodejs`
  organization's release team. Version 26.13.1 (LTS) was published on
  2026-11-11.
- **Reviewed by:** GPT-6 Luna for Daniel, 2026-11-13.

## 26.13.0-1 (2026-11-06)

- **Why depot ships it:** Daniel wants the newest stable Node, never an alpha (26 now; 27 is an alpha until 2027-04-22), updated through the package manager, as Arch does on `bridge` (26.13.0).
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release binaries, and build from source only when that is needed. building Node from source takes about an hour per target on a GitHub runner, for the same binary nodejs.org publishes. Fedora 44 ships Node 24 only (`nodejs24`), Debian 13 ships 20.
- **Source:** `node-v26.13.0-linux-x64.tar.xz` from `https://nodejs.org/dist/v26.13.0/`. Its sha256 `d28a96af6c38596f6d9d97c0ee531c13d238d757742387d1928de822d959e997` is in `SHASUMS256.txt.asc`, whose signature verifies with Richard Lau's release key `C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C`, listed in nodejs/node's README and in nodejs/release-keys. nvchecker follows stable tags only, so no alpha or RC is proposed.
- **Build:** none. The recipes unpack the archive and install the files as they are, with no network access beyond the pinned download.
- **Install:** no install script, no units, no links: plain files under `/usr/bin` and `/usr/lib/nodejs-latest` and docs. `check_package` enforces this on the built package. Neither recipe strips the binary or adds build-id links. `node`; npm in `/usr/lib/nodejs-latest/node_modules`, with `npm` and `npx` as two-line scripts, because upstream's are links. Headers (`include/`) are left out; node-gyp downloads its own. Node 26 no longer bundles corepack. The package is named `nodejs-latest` and installs npm under `/usr/lib/nodejs-latest`. Under the name `nodejs`, Debian's pin (depot only adds packages, priority 100) kept Debian's own Node 20, and on Fedora 44 `nodejs22` and `nodejs24` provide `nodejs` at epoch 1. A new name avoids both. It still installs `/usr/bin/node`, so it cannot sit beside a distribution's Node package: dpkg and rpm refuse the overlapping file.
- **On every bump:** check the new archive's sha256 against upstream's checksum file (and its signature, where upstream signs it) before adding the entry; `bump.sh` only records what it downloaded.
- **Upstream status:** active, the OpenJS Foundation's release team.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-06.
