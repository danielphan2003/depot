# carapace: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 1.8.4-1 (2026-11-23)

- **Change:** upstream's 1.8.4, two releases on from 1.8.2 (1.8.3 was tagged
  between nvchecker runs). The recipe is unchanged apart from the version and
  the source hash.
- **Source:** upstream tag tarball
  `https://github.com/carapace-sh/carapace-bin/archive/refs/tags/v1.8.4.tar.gz`,
  sha256 `b20afecb54a7ddaa12bc931ae081bf0e017c163ceb7d14bfcd571a286741ccd2`.
  The archive I downloaded has that hash, and so does the AUR's `carapace`
  PKGBUILD for 1.8.4, which is where the 1.8.2 pin came from as well.
  Upstream's `carapace-bin_1.8.4_checksums.txt` covers the release binaries,
  not this tag tarball, and the tag is lightweight: it points at commit
  `4ebe8372eb1873b1d616190d67173529f6927e69`, which GitHub reports as verified
  and authored by rsteube. As an extra check I compared the archive against
  that commit's tree: all 867 files are byte-identical (same blob hash, none
  extra, none missing), so the tarball is the tag's tree as GitHub generated
  it from `carapace-sh/carapace-bin`, not a fork or a mirror.
- **Build and dependencies:** unchanged. `go generate ./cmd/...`, then a
  static `go build -tags release` with `GOFLAGS=-mod=readonly`,
  `GOTOOLCHAIN=local` and `CGO_ENABLED=0`; makepkg, dh and rpm supply the
  distribution's flags. No module was added or removed. `go.mod` only bumps
  versions of modules already in `go.sum`, from publishers already trusted:
  carapace-sh's own `carapace`, `carapace-bridge`, `carapace-jjlex` and
  `carapace-spec`, plus `micromdm/plist`, `spf13/pflag`, `go.yaml.in/yaml/v3`,
  `golang.org/x/mod` and `gopkg.in/ini.v1`. So no new dependency publisher.
  Upstream's `Makefile`/`Dockerfile`/CI build steps do not enter depot's
  recipe, which still builds with the same three commands.
- **Upstream code read:** I compared `v1.8.2...v1.8.4`, 97 commits and 867
  files, reading the patches rather than the changelog. Most of the volume is
  generated completer code and `man/` YAML. The Go changes outside
  `completers/` are:
  - Shell snippets now pass their internals (aliases, builtins, functions,
    variables) through a `carapace_env` record, gated behind
    `CARAPACE_BUILTINS`, instead of inline `with-env` blocks, and
    `snippet_fixture_test.go` pins the emitted snippets for every shell. This
    is shell configuration text the binary prints, not code it runs.
  - `ion` support was removed from `carapace _carapace` and `invoke`.
  - The `gh` completer grew many new actions (hook, gist, milestone,
    environment, package, ruleset, run, runner, topic, user, alias, branch,
    body, coc, gitignore, extension, artifact). They call `gh` through
    `carapace.ActionExecCommand`, exactly as the existing `gh` actions did, and
    the new `gh/config` parsers read the local `hosts.yml`/environment, so no
    new network endpoint appears in the binary.
  - `git` repository search now reuses the shared `gh` completions, and the
    semantic-version action offers next prerelease, major, minor and patch
    values. Cosmetic completion changes only.
  - `CARAPACE_BUILTINS` gained values for the shells the snippets can now
    detect. No telemetry, no credential handling, no vendored blobs, and no
    new `os/exec`, `net/http` or `go:generate` in the non-completer Go diff.
- **Release process:** upstream now generates a man-page database with
  `carapace-man`, a separate tool from the same organization, pinned to
  v0.0.7 and installed with `curl | tar` inside upstream's own CI, and ships
  `carapace.db.gz` in its archives and nfpm packages under
  `/usr/share/carapace/man/`. depot's recipe calls `go build` directly, so it
  neither runs `carapace-man` nor installs that file: the binary works
  without it, and only `man`-page lookups through `carapace-man` would miss
  it. Nothing depot installs changes, and no extra download enters the build.
- **Install:** unchanged. `/usr/bin/carapace`, the README and the license, no
  install script, no units, nothing else. `check_package` enforces this on
  the built package.
- **Upstream status:** active, same owner (rsteube / `carapace-sh`), not
  archived. The release process changed only as described above, which
  depot's recipe does not follow and does not need to.
- **Reviewed by:** DeepSeek V4.1 Flash for Daniel, 2026-11-23.

## 1.8.2-1 (2026-11-03)

- **Why depot ships it:** the completion engine Daniel's nushell
  configuration loads (`dotfiles/nushell/config.nu` in factory). Replaces
  the AUR's `carapace-bin`. Built for every target so the shared shell
  configuration works on each machine; no distribution ships it.
- **Source:** upstream tag tarball
  `https://github.com/carapace-sh/carapace-bin/archive/refs/tags/v1.8.2.tar.gz`,
  sha256 `56b934e1c94cb4e10d912c0158a74f8b727e430e6d9c8aff5bfb99e124fa3ace`
  (the same hash the AUR pins). The `carapace-sh` organization is the
  author's (rsteube) own.
- **Starting recipe:** AUR `carapace` (aur.git `db93fc6`): `go generate
  ./cmd/...`, then a static `go build` with tags `release,force_all`. depot
  follows upstream's `.goreleaser.yml` instead: the same generate step and
  the `release` tag only.
- **Build:** `go build -trimpath -mod=readonly` with `GOTOOLCHAIN=local`, so
  Go never downloads a toolchain; modules come from proxy.golang.org, pinned
  by upstream's `go.sum`. Two `replace` lines point `spf13/pflag` and
  `kevinburke/ssh_config` at the carapace organization's own forks, pinned
  in `go.sum`. Debian builds with `golang-1.26-go` from trixie-backports
  (trixie's Go is 1.24; go.mod asks for 1.26); the binary is static, so
  nothing from backports is needed at run time.
- **Upstream code read:** `go generate` runs `cmd/carapace-generate` from
  the same tarball. It scans the source tree's completers and the
  go.sum-pinned action packages and writes Go files; the only command it
  runs is `go mod edit -json`. No network beyond the module proxy. At run
  time carapace executes the commands it completes for (e.g. `git` to list
  branches), as any completer does.
- **Install:** no install script, no units, nothing outside
  `/usr/bin/carapace`, its README and license. `check_package` enforces this
  on the built package.
- **Upstream status:** active, same owner as before, not archived; no change
  to the release process.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
