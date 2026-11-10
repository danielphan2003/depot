# atuin: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 18.24.6-1 (2026-11-10)

- **Why depot ships it:** Daniel wants one current atuin on every machine.
  Arch ships it. Fedora 44's rpm is 18.12.1 and Debian 13's is 18.6.1 (from
  the distributions' package indexes, 2026-11-10). atuin 18.12.1 and older
  generate a nushell integration that calls `job spawn -t atuin`, a flag
  nushell 0.116 (also from depot) renamed to `--description`: a parse error
  that stops nushell at start. atuin 18.13 dropped the tag. 18.12.1 also
  names two keybindings `atuin`, which nushell 0.116 warns about on every
  start; 18.24.6 does not. Debian's 18.6.1 does not call `job spawn` at all.
  It ships here to keep one version across machines. Only the Debian and
  Fedora recipes exist; Arch keeps its own package.
- **Why a binary:** Daniel, 2026-11-06: repackage upstream's release
  binaries, and build from source only when that is needed. Daniel,
  2026-11-09: a package whose upstream binary carries a GitHub attestation
  uses that binary. This one does.
- **Source:**
  `https://github.com/atuinsh/atuin/releases/download/v18.24.6/atuin-x86_64-unknown-linux-musl.tar.gz`
  from the GitHub release of `atuinsh/atuin` (the project's own
  organization), sha256
  `49b6e7a93cd6d8c77ee02bdb0eef0acff4c80ddaa0efb00c8179285771043698`. It
  matches the release's `sha256.sum` and the asset's own `.sha256` file.
- **Attestation:** SLSA build provenance (`https://slsa.dev/provenance/v1`)
  signed by `atuinsh/atuin/.github/workflows/release.yml@refs/tags/v18.24.6`,
  source commit `c71cd7baad5aaf0ff4d19db369d247f08da76ec9`, with this file's
  `atuin` binary and the archive among its subjects. `lint.sh` checks it with
  `gh attestation verify`, pinned to that workflow and tag, on every run.
  This is the stronger kind: it proves upstream's workflow built the file
  from the tag, not only that upstream published it. The release itself is not
  an immutable release, so `attest=release` would not have worked.
- **Binary:** static-pie (musl), x86-64: no interpreter and no shared
  libraries, so no library dependencies on any target (rpm records only
  `rtld(GNU_HASH)`, which glibc provides). The musl build was chosen over
  `linux-gnu`, which is attested too, so a glibc on the target can never be
  too old (as `railway-cli` and `zellij`). It is built with upstream's release
  profile, not the distributions' flags. Upstream strips it; depot does not
  strip it again (54 MB installed).
- **Build:** none. The recipes unpack the archive and install the binary as it
  is, with no network access beyond the pinned download. The source was not
  read for this entry beyond the self-updater below: atuin is a widely used
  project with a public release workflow, and this version's code is the one
  Arch ships.
- **Install:** `/usr/bin/atuin` plus the license and README; no scriptlets, no
  units, no links, which `check_package` enforces. `CHANGELOG.md` is left out
  of the rpm; the deb ships it as the upstream changelog (debhelper's
  default). `atuin-server` is a separate archive and is not packaged.
  Built and installed in clean `fedora:44` and `debian:trixie` containers
  on 2026-11-10, and `test.sh` passes: the binary runs and `atuin init nu`
  works. Its output parses and starts cleanly under nushell 0.116.1, with
  no `job spawn -t` and no warnings.
- **Network behavior:** `sync_address` defaults to Atuin's hosted server and
  `update_check` is on by default (a version query); both are user
  configuration. The self-updater, `atuin update`, refuses to run without the receipt that
  upstream's installer script writes, and tells the user to update through
  their package manager, so an install from depot will not replace itself
  (`crates/atuin/src/command/client/update.rs` at the tag).
- **Upstream status:** active, same organization, several releases a month.
- **Reviewed by:** Claude (Sonnet 5.5) for Daniel, 2026-11-10.
