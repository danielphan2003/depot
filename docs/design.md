# depot design

Why depot builds where it builds, serves from where it serves, and holds
its key where it holds it. Recorded 2026-11-02.

## Build on GitHub-hosted runners

Each job runs in a fresh GitHub-hosted VM, inside a container of the target
distribution. The VM is discarded after the job. A self-hosted runner on
one of Daniel's own machines was weighed against that. It would execute
whatever code a recipe pulls in, with the privileges of a real user on a
real machine: his files, his keys, his network. Upstream build code is
exactly the code depot does not trust yet, so a compromised build would own
that machine instead of a disposable VM.

GitHub-hosted runners cost nothing here, since public repositories get
unlimited Linux minutes.

The container is not the security boundary: GitHub's container jobs can
reach the runner's Docker socket. The boundary is the per-job VM, which is
discarded afterwards, and the absence of secrets in the jobs that run
upstream code.

## Serve from R2 behind a Worker

The repositories live in the R2 bucket `depot` (APAC). The Worker `depot`
([`infra/pkgs/`](../infra/pkgs)) serves them at `https://pkgs.c-137.me`.
Both are declared, with the GitHub settings below, in an
[Alchemy](https://alchemy.run) stack, the same tool T3 Code's infrastructure
uses. Anyone can read. CI writes with a bearer token
(`DEPOT_UPLOAD_TOKEN`) that only this Worker accepts. With an upload token, CI
needs no Cloudflare API key and no R2 S3 credentials, and the token can do
nothing outside this bucket. Inside the bucket, it cannot get a file
signed: `publish.sh` verifies every file it downloads against the key, or
against the signed `Packages` file for `.deb`s, before listing it again.

Reads need no login because the repositories are signed. A tampered file
fails pacman's, apt's or dnf's signature check, whatever path it took.
Signatures do not stop a rollback or a freeze: someone who controls the
bucket or the path could serve an older, validly signed index and hold a
machine at old versions. None of the three formats checks freshness as
depot publishes them. The packages are builds of open-source code, so they
reveal nothing beyond which tools Daniel uses.

| Option | Cost today | Independent of the repository | Notes |
| --- | --- | --- | --- |
| **R2 + Worker (chosen)** | cents a month at most | yes | depot holds a few tens of MB. R2 storage is free up to 10 GB per account and $0.015 per GB-month past that, and egress is free. Requests fit the Workers free plan (100,000 a day). |
| GitHub Releases | $0 | no | One flat list of assets per release, so the repository layouts that apt and dnf expect do not fit; private repositories would also need a login. |
| GitHub Pages | $0 | no | Publishing means committing every package to a branch, and it ties distribution to the repository's visibility. |
| R2 public bucket (`r2.dev`) | same as R2 | yes | Cloudflare rate-limits `r2.dev` and says not to use it in production. |

The Worker answers only on its custom domain, `pkgs.c-137.me`; its
`workers.dev` address is off. Bot Fight Mode is off for the whole
`c-137.me` zone, declared in the same stack: it challenged every request
from a cloud IP, which shut out both CI and cloud machines, and the Free
plan cannot exempt one hostname. Moving to another domain only changes the
URL in each machine's repository file.

## Sign with one OpenPGP key held in GitHub Actions

One ed25519 OpenPGP key signs everything:

- pacman: each package (`.sig`) and the database (`depot.db.sig`);
- apt: the `Release` file (`InRelease` and `Release.gpg`), which lists the
  hash of every `.deb`;
- rpm: each package (`rpmsign`) and the metadata (`repomd.xml.asc`).

The private key exists only in the secret `DEPOT_SIGNING_KEY` of the
`release` environment. It was generated in a throwaway GnuPG home and piped
straight into `gh secret set`, and no other copy exists. A secrets manager
was considered, but CI would then need that manager's token stored as a
GitHub secret, which moves the problem without removing it.

Only the `publish` job reads the key, and it runs only depot's own scripts.
They sign and index packages and never execute one. The distribution tools
they need are installed in an earlier step that gets no secrets. Upstream
code runs in the `build` job, which has no secrets and a read-only token.
`publish.sh` refuses to run unless the key's fingerprint matches
[`keys/depot.asc`](../keys/depot.asc).

Upstream build code runs as root in its container and can write anything
into the build output. So `publish.sh` and `test-repo.sh` sign nothing that
fails `check_package` in `scripts/lib.sh`. The package's name must belong to
a recipe for that target. It may declare no relations to other packages
(replaces, provides, conflicts, breaks, obsoletes, pre-depends, supplements,
enhances) and must not be Essential. It may not run install scripts or
triggers, or carry file
capabilities, extended attributes, links, setuid binaries, or files not
owned by root or writable by group or others. Its files must
sit under an allowlist (`usr/bin`, `usr/lib{,64}/<name>`,
`usr/share/{doc,licenses}/<name>`, `usr/share/man`), because a deny-list of
the places where files run as root (pacman hooks, systemd units, dbus,
modprobe, kernel-install, ...) can never be complete. On Arch, the
`.PKGINFO` must hold only known keys in makepkg's exact format, since
`repo-add` turns each key into a shell variable while the signing key is in
the job. The worst a hostile upstream can then ship is malicious programs in
`usr/bin`, under its own package name, with no privilege beyond the user who
runs them. That is the risk of running the tool at all, and auditing each
upstream change addresses it. `scripts/test-check-package.sh` keeps a
crafted package for every bypass found so far, and CI runs it on every
build.

The key and the upload token are secrets of the `release` environment,
which only `main` may deploy to. A ruleset makes every change to `main` go
through a pull request whose checks pass, and forbids force pushes and
deletion. A workflow on any other branch, or in a pull request from a fork,
never sees the key. So the boundary is merging to `main`: Daniel merges,
and agents and bots only open pull requests. Anyone with admin rights could
still loosen the ruleset or the environment, so admin rights stay with
Daniel. The `open-prs` job in `bump.yml` holds a write token, so it runs
only depot's own scripts, which open pull requests and never merge them. nvchecker and its dependencies run in the read-only `check` job,
installed from hash-pinned requirements (`ci/nvchecker.txt`), and the job
that can write checks their output before using it. On Arch the build runs
as an unprivileged user; on Debian and Fedora it runs as root in its
container, which is why `check_package` exists. Because `publish.sh`
compares the secret with `keys/depot.asc`, the repository also decides which
key is valid, one more reason merging to `main` is the boundary.

Machines trust the key by its fingerprint, which this README and each
machine's configuration record in git:

- pacman: `pacman-key --add` and `pacman-key --lsign-key`, with
  `SigLevel = Required DatabaseRequired` for `[depot]`;
- apt: the key in `/etc/apt/keyrings/depot.asc`, named by `Signed-By` in
  the source file;
- rpm: `gpgkey=` in the `.repo` file, with `gpgcheck=1` and
  `repo_gpgcheck=1`.

Machines also limit what depot can touch, whatever happens in CI. dnf's
`includepkgs=` lists the packages it may take from depot. An apt pin at
priority 100 stops a depot package from upgrading a Debian package of the
same name. pacman has no per-repository filter, so `[depot]` sits last in
`pacman.conf`, where distribution packages win, and `check_package` refuses
`replaces`.

The key does not expire, so nothing breaks if nobody remembers a renewal.
Rotation is cheap instead.

### Rotate the key

Rotate when the key may have leaked, or when anyone wants a fresh one.
Losing the key is not an emergency: rotate.

For a planned rotation:

1. Generate a new key in a throwaway `GNUPGHOME` under your scratch
   directory, and export its public key. Keep that `GNUPGHOME` until
   step 3.
2. On each machine, trust the new public key alongside the old one. On
   pacman, `pacman-key --add` and `--lsign-key`. On apt, put both keys in
   the `Signed-By` file. On rpm-ostree and dnf, list both files in
   `gpgkey=`, separated by a space; rpm-ostree reads that line on every
   operation, and Kinoite's rpm database is read-only.
3. Move the old public key to `keys/depot-previous.asc` and put the new one
   in `keys/depot.asc`. Update the fingerprint in the README and wherever
   the machines' configuration records it. Pipe the armored secret key into
   `gh secret set DEPOT_SIGNING_KEY --env release`, never printing it, and
   delete the throwaway `GNUPGHOME`. Merge. Until the merge, `publish.sh`
   refuses to run because the fingerprints differ.
4. Run `build.yml` on `main` with `publish` and `resign` ticked.
   `publish.sh` verifies the published files against both keys, then
   re-signs every package and index with the new key.
5. Remove the old key from each machine: `pacman-key --delete`, the old key
   in the `Signed-By` file, and the old file in `gpgkey=`. Then delete
   `keys/depot-previous.asc`.

If the old key leaked, remove it from every machine first (step 5). Then do
steps 1, 3 and 4, and trust only the new key in step 2. Machines fail
closed in between.

## Catch library breakage

A distribution can bump a library that a depot package links against, for
example ffmpeg under mpv or Qt 6 under quickshell. The old binary then
fails to start. depot handles that in four places:

- **Every build upgrades the container first,** so the packages link
  against the distribution's current libraries.
- **Soname dependencies.** rpm and `dh_shlibdeps` record the exact library
  sonames on their own. On Arch, adding `libfoo.so` to `depends` makes
  makepkg record `libfoo.so=<soname>`. pacman then refuses an upgrade that
  would break the package, instead of breaking it silently.
- **The daily canary** installs the published packages into fresh,
  upgraded containers. It runs each smoke test and checks every installed
  binary with `ldd` for a missing library. A failure opens an issue.
- **The weekly rebuild** catches recipes that no longer build.

The fix is `scripts/bump-release.sh <package> <target>`. The new release
number gives the rebuilt package a new file name, so machines upgrade to
it.

## Version bumps with nvchecker

nvchecker runs in a GitHub Actions job with the repository's own
`GITHUB_TOKEN`. Renovate would need the Mend app installed with write
access to the repository, or a self-hosted Renovate with a personal token.
nvchecker needs neither, and Arch packagers already use it for this job.

A pull request opened with `GITHUB_TOKEN` does not trigger `pull_request`
workflows. `nvcheck.sh` therefore starts `build.yml` on the PR's branch
with `workflow_dispatch`, which `GITHUB_TOKEN` is allowed to do. The
checks then show on the PR.

## Fedora releases

The `.repo` file uses `$releasever`, so after a machine rebases to
Fedora 45 it asks for `fedora/45`. Add a `fedora-45` target to depot, and
let it publish, before rebasing. Otherwise the rebase fails on the missing
repository.

## Published files are immutable

`publish.sh` never replaces a file that is already in the bucket. Without
that rule, pacman's cache would keep an old file under the new file's name
and fail its checksum, and two machines could install different bytes under
one version. A changed recipe therefore needs a new release number. The
script keeps the newest two versions of each package. apt and dnf list both,
so a machine can roll back one release with the package manager. pacman's
database lists only the newest, so on Arch a rollback is
`pacman -U <url of the kept file>`.
