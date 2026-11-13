# lazygit: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.66.3-1 (2026-11-13)

- **Why depot ships it:** factory's shared tool list has lazygit; Arch and
  Debian 13 ship it, Fedora 44 does not.
- **Source:** the recipe downloads the upstream `v0.66.3` tag tarball over
  HTTPS and pins sha256
  `49e80d28e03e53048105f6ebb5afefbe5caacffa8549347d8a59eab3a00dafe1`.
  The archive I downloaded has that hash. Upstream's `checksums.txt` lists
  the release binaries but not this GitHub source tarball. The annotated tag
  is unsigned, and the GitHub attestation lookup for this archive returns
  404. **Not sure:** no upstream checksum, signature, or attestation covers
  the source archive. Hold this update for Daniel.
- **Binary attestation:** not applicable. depot builds the source tarball;
  it does not repackage an upstream binary.
- **Starting recipe:** unchanged from the depot recipe based on upstream's
  `.goreleaser.yml`. The PR updates only the version and source hash in
  `package.env` and the RPM spec's version and changelog.
- **Build and dependencies:** the RPM spec still runs `go build -mod=vendor`
  with `GOTOOLCHAIN=local` and `CGO_ENABLED=0`. `go.sum` and
  `vendor/modules.txt` pin the vendored modules, and the build does not fetch
  dependencies. The diff adds no external dependency. It uses the distro's Go
  toolchain with no C compilation, so C compiler hardening flags do not apply.
- **Install:** no install script, maintainer script, or trigger. The RPM spec
  installs only `/usr/bin/lazygit`, the license, and the README.
- **Upstream code read:** I compared `v0.66.2...v0.66.3`. The diff adds
  checks for suspicious `.gitmodules` names and paths, a containment guard
  before deleting submodule metadata, and tests for traversal and linked
  worktrees. It adds no network calls, telemetry,
  credential handling, binary blobs, or external modules. The changed Go
  imports are standard-library or existing internal packages. The build and
  release workflows are unchanged.
- **Upstream status:** active and not archived, with the same owner,
  `jesseduffield`. Release 0.66.3 was published on 2026-11-07; the release
  process is unchanged.
- **Reviewed by:** GPT-6 Luna for Daniel, 2026-11-13.

## 0.66.2-1 (2026-11-03)

- **Why depot ships it:** factory's shared tool list has lazygit; Arch and
  Debian 13 ship it, Fedora 44 does not.
- **Source:** upstream tag tarball
  `https://github.com/jesseduffield/lazygit/archive/refs/tags/v0.66.2.tar.gz`,
  sha256 `fcaad0909af765ef87bd873164a4de78435515ab4d8b04f58d6ad51e8ecd00e5`.
  The author's own repository.
- **Starting recipe:** written for depot, after upstream's `.goreleaser.yml`
  (`-X main.version`, `main.buildSource`).
- **Build:** `go build -mod=vendor -trimpath` with `GOTOOLCHAIN=local`:
  upstream commits its dependencies in `vendor/`, which the go command
  checks against `vendor/modules.txt` and `go.mod`. No downloads. 70
  modules.
- **Upstream code read:** The `go:generate` lines are all inside `vendor/`
  and are not run. At run time lazygit runs `git`.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/lazygit` and its docs. `check_package` enforces this on the
  built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
