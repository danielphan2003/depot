# nodejs: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 26.13.0-1 (2026-11-06)

- **Why depot ships it:** Daniel wants the newest stable Node, never an alpha (26 now; 27 is an alpha until 2027-04-22), updated through the package manager, as Arch does on `bridge` (26.13.0).
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release binaries, and build from source only when that is needed. building Node from source takes about an hour per target on a GitHub runner, for the same binary nodejs.org publishes. Fedora 44 ships Node 24 only (`nodejs24`), Debian 13 ships 20.
- **Source:** `node-v26.13.0-linux-x64.tar.xz` from `https://nodejs.org/dist/v26.13.0/`. Its sha256 `d28a96af6c38596f6d9d97c0ee531c13d238d757742387d1928de822d959e997` is in `SHASUMS256.txt.asc`, whose signature verifies with Richard Lau's release key `C82FA3AE1CBEDC6BE46B9360C43CEC45C17AB93C`, listed in nodejs/node's README and in nodejs/release-keys. nvchecker follows stable tags only, so no alpha or RC is proposed.
- **Build:** none. The recipes unpack the archive and install the files as they are, with no network access beyond the pinned download.
- **Install:** no install script, no units, no links: plain files under `/usr/bin` and `/usr/lib/nodejs` and docs. `check_package` enforces this on the built package. Neither recipe strips the binary or adds build-id links. `node`; npm in `/usr/lib/nodejs/node_modules`, with `npm` and `npx` as two-line scripts, because upstream's are links. Headers (`include/`) are left out; node-gyp downloads its own. Node 26 no longer bundles corepack. The package is named `nodejs`: on Debian it supersedes Debian's own nodejs (20). On Fedora it carries `Epoch: 2`, because Fedora 44's `nodejs22` and `nodejs24` provide `nodejs` at epoch 1, and `dnf install nodejs` picked Node 22 in CI before the epoch was added.
- **On every bump:** check the new archive's sha256 against upstream's checksum file (and its signature, where upstream signs it) before adding the entry; `bump.sh` only records what it downloaded.
- **Upstream status:** active, the OpenJS Foundation's release team.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-06.
