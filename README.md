# depot

depot builds packages that Daniel's machines need but their distributions
do not ship. CI builds each one from a reviewed recipe and signs it. It then
publishes three package repositories that the machines install from with
their own package manager. No machine builds from source, and none trusts
an AUR maintainer.

| Target | Distributions | Format | Repository URL |
| --- | --- | --- | --- |
| `arch` | Arch, CachyOS | pacman | `https://pkgs.c-137.me/arch/$arch` |
| `debian-trixie` | Debian 13 | apt | `https://pkgs.c-137.me/debian`, suite `trixie` |
| `fedora-44` | Fedora 44, including Atomic desktops | rpm | `https://pkgs.c-137.me/fedora/$releasever/$basearch` |

Every repository is signed with one OpenPGP key:

```
E3450B8E60A2F0FEF0EF26F6583D558DBAF27F7E
```

The public key is [`keys/depot.asc`](keys/depot.asc), and the server copies
it to `https://pkgs.c-137.me/depot.asc`. A downloaded copy is only as
trustworthy as its fingerprint, and apt and dnf trust every key in a key
file. So import the download into a throwaway keyring and export only this
fingerprint before you trust it.

[`docs/design.md`](docs/design.md) explains the choices: GitHub-hosted
runners, R2 behind a Worker, where the signing key lives, and how library
breakage is caught.

## Packages

| Package | Version | Targets | Why |
| --- | --- | --- | --- |
| [`age-plugin-fido2-hmac`](packages/age-plugin-fido2-hmac) | 0.5.0 | all | lets age decrypt with a FIDO2 key |
| [`avbroot`](packages/avbroot) | 3.37.1 | arch | patches Android OTA images for root |
| [`bun`](packages/bun) | 1.4.4 | debian-trixie, fedora-44 | JavaScript runtime; upstream's binary, Arch ships it |
| [`carapace`](packages/carapace) | 1.8.2 | all | shell completion engine |
| [`custota-tool`](packages/custota-tool) | 6.8 | arch | signs Custota OTA update metadata |
| [`dpibreak`](packages/dpibreak) | 0.6.2 | arch | system-wide DPI circumvention |
| [`dufs`](packages/dufs) | 0.47.0 | arch | small file server |
| [`ente-cli`](packages/ente-cli) | 0.4.2 | arch | Ente command-line client |
| [`fcitx5-lotus`](packages/fcitx5-lotus) | 6.0.4 | arch | Vietnamese input method, with its uinput server (see its `allow`) |
| [`flyctl`](packages/flyctl) | 0.5.2 | arch | Fly.io command-line client |
| [`freesmlauncher`](packages/freesmlauncher) | 2.3.1 | arch | Minecraft launcher (desktop app, see its `allow`) |
| [`ghq`](packages/ghq) | 1.11.2 | debian-trixie, fedora-44 | repository manager; Arch ships it |
| [`gitea-tea`](packages/gitea-tea) | 0.16.0 | debian-trixie, fedora-44 | Gitea CLI (`tea`); Arch ships it as `tea`, Debian's `tea` is an editor |
| [`lazygit`](packages/lazygit) | 0.66.2 | fedora-44 | git TUI; Arch and Debian ship it |
| [`nodejs`](packages/nodejs) | 26.13.0 | debian-trixie, fedora-44 | Node.js, newest stable release; upstream's binary |
| [`nushell`](packages/nushell) | 0.116.1 | debian-trixie, fedora-44 | Daniel's shell; upstream's binary, Fedora's is too old |
| [`run0-sudo-shim`](packages/run0-sudo-shim) | 1.4.2 | arch | `/usr/bin/sudo` through run0 and polkit; `provides`/`conflicts` sudo (see its `allow`) |
| [`starship`](packages/starship) | 1.27.0 | fedora-44 | shell prompt; Arch and Debian ship it |
| [`zellij`](packages/zellij) | 0.45.1 | debian-trixie, fedora-44 | terminal multiplexer; upstream's static binary |

Only packages Daniel asked for go in here. Recipes build from source unless upstream's own release binary will do (Daniel, 2026-11-06): `bun`, `nodejs`, `nushell` and `zellij` repackage upstream's binaries, pinned by sha256 and checked against upstream's checksums.

## Layout

```
packages/<name>/
  package.env          upstream version, tarball URL and sha256
  AUDIT.md             what was reviewed, for every version
  allow                extra paths check_package accepts (optional, approved)
  test.sh              smoke test, run after a clean install
  arch/PKGBUILD        pacman recipe (optional)
  debian/              Debian packaging, binary-only build (optional)
  rpm/<name>.spec      rpm recipe (optional)
nvchecker.toml         where each package's upstream releases come from
ci/nvchecker.txt       hash-pinned nvchecker for bump.yml
keys/depot.asc         public signing key
scripts/               build, sign, publish, test and bump scripts
infra/pkgs/            the Alchemy stack: the Worker at pkgs.c-137.me, its
                       bucket, and the GitHub settings that guard publishing
.github/workflows/
  build.yml            build, test, publish (on main), verify
  canary.yml           daily install of the published packages
  bump.yml             daily nvchecker run, opens update PRs
```

A package builds for every target whose recipe directory exists.

## What CI does

1. `build.yml` runs on every pull request, on pushes to `main`, and weekly.
   A change that touches only docs (`docs/**` and `*.md`) builds nothing: a
   push to `main` does not start the workflow, and a pull request runs only
   `lint` and the required `ok` check.
   - `lint` checks that every recipe agrees with `package.env` and runs
     ShellCheck.
   - `build` builds each package for each target in a job of its own
     (`scripts/matrix.sh` lists them), in a container of that distribution,
     after a full upgrade, so packages link against today's libraries. One
     package's build code never sees another's output.
   - `repo` gathers each target's packages with `scripts/collect.sh`, which
     refuses a job's output unless every package in it has that job's
     package name. It runs `scripts/test-check-package.sh`, which feeds
     `check_package` crafted hostile packages and the real ones, then signs
     a test repository with a throwaway key.
   - `test` installs from that test repository into a fresh container. It
     runs each `test.sh` and fails if a binary has a missing library.
   - `publish` (pushes to `main`, or a manual run with `publish` ticked) signs with the real key and uploads.
     A package file that is already published is never replaced (only a
     key rotation re-signs it); the indices are rebuilt on every publish.
     Every package, new or already published, must pass `check_package` in
     `scripts/lib.sh`: its name must match a recipe; it may declare no
     relations to other packages (replaces, provides, conflicts, breaks,
     obsoletes, pre-depends, supplements, enhances) and must not be
     Essential; it may carry no install scripts, triggers, file
     capabilities or setuid files; its files must be owned by root and
     not group- or world-writable; and it may install only
     plain files under `usr/bin`, `usr/lib{,64}/<name>`,
     `usr/share/{doc,licenses}/<name>` and `usr/share/man`. Files already in
     the bucket are verified against the key before they are listed again.
   - `verify` installs from the live URL in fresh containers.
2. `canary.yml` repeats the live install every day. If a distribution
   library bump broke a published binary, the canary opens an issue.
3. `bump.yml` runs nvchecker every day, from hash-pinned requirements in a
   job with a read-only token. A second job opens a PR for each new
   upstream release and starts `build.yml` on that PR's branch. Lint fails
   on those PRs until `AUDIT.md` has an entry for the new version.

## Add a package

Do this only for a package Daniel asked for.

1. Find a recipe to start from: the AUR PKGBUILD, Debian's or Fedora's
   packaging, or upstream's own instructions. Never copy one without
   reading it. Work through the [audit checklist](#audit-checklist).
2. Create `packages/<name>/` with `package.env`, `test.sh`, `AUDIT.md`,
   and one recipe directory per target. Use
   [`age-plugin-fido2-hmac`](packages/age-plugin-fido2-hmac) as the model.
3. Add a `[<name>]` entry to `nvchecker.toml`.
4. Build and test locally in a throwaway container. Nothing gets installed
   on the host:

   ```bash
   podman run --rm -v "$PWD:/src:Z" -w /src docker.io/library/archlinux:base-devel \
     bash -c 'scripts/build.sh arch out/arch <name> && scripts/test-repo.sh arch out/arch repo/arch'
   podman run --rm -v "$PWD:/src:ro,Z" -w /src docker.io/library/archlinux:latest \
     scripts/install-test.sh arch file:///src/repo/arch repo/arch/depot-test.asc
   ```

   Leave out `<name>` to build every package. For the other targets, use
   `debian-trixie` with `debian:trixie`, and `fedora-44` with
   `registry.fedoraproject.org/fedora:44`. Debian builds may use build tools
   from trixie-backports (`golang-1.26-go`), never runtime libraries: the
   install test runs without backports.
5. Run `scripts/lint.sh`, open a PR, and wait for `build` to pass.

## Update a package

nvchecker opens `feat(<name>): update to <version>` PRs on its own. To bump
a package by hand, run `scripts/bump.sh <name> <version>`. Either way the
PR only moves the recipes to the new tag. Before merging:

1. Read the upstream diff between the two tags. The PR body links it.
2. Work through the [audit checklist](#audit-checklist) for what changed.
3. Add a `## <version>-<release> (<date>)` entry to
   `packages/<name>/AUDIT.md`. Lint fails without it.
4. Wait for `build` to pass, then merge.

If the audit rejects an update, close its PR and keep the
`bump/<name>-<version>` branch: nvchecker then stops proposing that version.
To have it proposed again, delete the branch.

To rebuild without a new upstream version, run
`scripts/bump-release.sh <name> [target...]`. You need a rebuild when the
canary reports a missing library, or when a published recipe changes.
Published files never change, so a rebuild needs a new release number.

## Audit checklist

Read the recipe and the upstream change with these questions. Record the
answers in `AUDIT.md`. If any answer is "no" or "not sure", stop and ask
Daniel.

Sources:

- Does the recipe download only upstream's release artifact or tag
  tarball, over HTTPS, pinned by sha256?
- Does the tarball come from the upstream project itself, and not from a
  fork, a mirror, or the recipe author's account?
- If the build fetches dependencies (Go modules, crates, npm packages),
  does a lock file from upstream pin them (`go.sum`, `Cargo.lock`,
  `package-lock.json`)? Does the build refuse to change that lock file
  (`-mod=readonly`, `--locked`, `npm ci`)?
- Did the update add dependencies? Who publishes each new one?

Build:

- Does the build run only the language's normal build and test commands?
  Look for `curl | sh`, extra downloads, or code generated from the
  network.
- Are compiler flags the distribution's own (hardening, PIE)?

Install:

- Do the recipes have no install scripts? Look for PKGBUILD `install=`,
  Debian maintainer scripts, and rpm `%pre`, `%post` and triggers.
  `lint.sh` rejects them in recipes, and `check_package` rejects them in
  built packages. Adding one needs Daniel's approval.
- Does the package install only plain files under `usr/bin`,
  `usr/lib{,64}/<name>`, `usr/share/{doc,licenses}/<name>` and `usr/share/man`?
  Files elsewhere can run as root without any script: pacman hooks, systemd
  units, `sysusers.d`, `tmpfiles.d`, udev, polkit and dbus files. So
  `check_package` allows only those directories, and refuses links, setuid
  files and file capabilities. Widening that list, for example for shell
  completions or a systemd unit, needs Daniel's approval. An approved
  exception for one package goes in `packages/<name>/allow`, one
  `path <regex>` line per file (whole paths, no leading slash), with a
  comment saying why and an `- **Allowed paths:**` item in `AUDIT.md`.
  Grant exact files, never a directory such as `usr/lib/systemd/system`.
  The same file can grant an Arch package `relation provides <name>` or
  `relation conflicts <name>`; every other relation stays refused.

Upstream change:

- Read the diff, not only the changelog. Look for new network access,
  telemetry, credential handling, obfuscated or vendored binary blobs, and
  changes to the build itself (`Makefile`, `build.rs`, `go:generate`, CI).
- Has upstream changed hands or been archived, or has the release process
  changed?

## Operate

- **Deploy the infrastructure:** [Alchemy](https://alchemy.run) manages
  the `Depot` stack in [`infra/pkgs/alchemy.run.ts`](infra/pkgs/alchemy.run.ts):
  the R2 bucket, the Worker and its custom domain, the `release`
  environment, the `main` ruleset and the upload token. Bot Fight Mode for
  `c-137.me` stays off in Cloudflare's settings, outside Alchemy: with it
  on, Cloudflare challenges CI and cloud machines before they reach the
  Worker. In `infra/pkgs/`,
  run `pnpm install` and `pnpm run check`, then
  `GITHUB_TOKEN=$(gh auth token) pnpm run deploy`. Cloudflare access comes
  from the `default` Alchemy profile (`pnpm exec alchemy profile edit --add
  Cloudflare`, which signs in through the browser). Alchemy keeps its state
  in the account's `alchemy-state-store` Worker, encrypted. Run
  `pnpm run plan` first to see what would change. The bucket and the
  environment are retained even if the stack is destroyed.
- **Publish:** merging to `main` publishes. Only `main` can: the signing
  key and the upload token are secrets of the `release` environment, which
  is limited to `main`. To publish again without a change (with `resign`
  or `withdraw`), run `build.yml` on `main` from the Actions tab with
  `publish` ticked.
- **Withdraw a bad release:** revert or fix the recipe in a PR, giving it a
  version that sorts higher (or an epoch). Then run `build.yml` on `main`
  with `publish` ticked and the bad file names in `withdraw`, for example
  `age-plugin-fido2-hmac-0.6.0-1-x86_64.pkg.tar.zst`. Machines that already
  installed it keep it until the next upgrade.
- **After tightening `check_package`:** `publish.sh` checks the packages
  already in the bucket too, so a published file that the new rules refuse
  stops every publish for its target. Withdraw that file by name in the
  same run. A fresh build that the rules refuse fails the run instead; fix
  its recipe. The check is strict on purpose: for example, a PKGBUILD with
  `groups=()` or `backup=()` is refused until those `.PKGINFO` keys are
  allowed in `check_package`.
- **Rotate the signing key:** [`docs/design.md`](docs/design.md#rotate-the-key).
- **Rotate the upload token:** Alchemy generates it and gives the same
  value to the Worker and to the `release` environment. Rename the
  `UploadToken` resource in `alchemy.run.ts` (for example to
  `UploadToken2`) and deploy; Alchemy mints a new value and updates both.
- **Repository settings:** the stack declares the `release` environment
  (deployments from `main` only; it holds `DEPOT_SIGNING_KEY` and
  `DEPOT_UPLOAD_TOKEN`, and the repository has no other secrets) and the
  ruleset `main` (a pull request and the `ok` check, no force push or
  deletion, no bypass). The signing key is set by hand, never through
  Alchemy, so it never enters Alchemy's state. These were set once with
  `gh api`:
  - workflows get a read-only token by default, and every outside
    contributor's first workflow run waits for approval;
  - workflows may create pull requests (2026-11-06), so `bump.yml` can open
    its update PRs. GitHub grants this together with approving PRs, which
    gains nothing here: the ruleset requires no approvals, and only
    `bump.yml`'s `open-prs` job, which runs depot's own scripts, gets a token
    that can write pull requests;
  - secret scanning and push protection are on.
