# freesmlauncher: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 2.3.2-1 (2026-11-13)

- **Why depot ships it:** Daniel's Minecraft launcher on `bridge` (1.9 GB
  of instances). Replaces the AUR's `freesmlauncher-bin`, which repackaged
  upstream's portable build under `/opt`.
- **Source:** the recipe downloads FreesmTeam's 2.3.2 source release over
  HTTPS and pins sha256
  `a0a87486dc839db9c3591bf5f363b397edecf7a8ec8f694b48f3c978c015e1b8`.
  The 19,233,731-byte archive I downloaded has that hash. It matches the
  `digest` GitHub reports for the release asset. The release has no checksum
  file or detached signature, and the GitHub attestation lookup returns 404.
  The release workflow does not create a checksum file or sign the archive.
  **Not sure:** GitHub's server-computed digest confirms the hosted bytes, but
  it is not an upstream checksum file, signature, or attestation. Hold this
  update for Daniel's decision on that missing provenance.
- **Binary attestation:** not applicable. depot builds this source archive;
  it does not repackage an upstream binary.
- **Starting recipe:** unchanged from the AUR `freesmlauncher` recipe
  (`aur.git` commit `fade773`), previously reviewed in the 2.3.1 entry.
  This PR changes only the version and source sha256 in `package.env` and
  `arch/PKGBUILD`.
- **Build and dependencies:** the recipe still uses CMake, Ninja, and `ctest`
  with Arch's compiler flags. The depot build does not fetch dependencies.
  Upstream's release workflow includes the submodules in the source archive.
  The update adds no recipe dependencies or install commands. Upstream raises
  its Qt minimum to 6.8; `Qt6::Concurrent` was already listed as a component.
- **Install:** no recipe install script, maintainer script, or trigger. The
  upstream diff changes no install rules. The existing `allow` paths remain
  unchanged; no new install path is needed.
- **Upstream code read:** I compared the actual `2.3.1...2.3.2` tags. The PR
  body link uses nonexistent `v`-prefixed tags, so I used the unprefixed tag
  names. The diff adds PNG completeness checks and asynchronous screenshot
  loading, plus tests with a PNG fixture. It changes Ely.by OAuth to use
  PKCE S256, updates its client identifier, and fixes the request completion
  connection. I found no new network endpoint, telemetry, credential export,
  obfuscated code, or vendored executable. The CodeQL workflow only updates
  its Qt version; the release workflow is unchanged.
- **Upstream status:** active and not archived. The repository is owned by
  FreesmTeam. Release 2.3.2 was published on 2026-11-03, and the release
  workflow is unchanged from the prior tag.
- **Reviewed by:** GPT-6 Luna for Daniel, 2026-11-13.

## 2.3.1-1 (2026-11-03)

- **Why depot ships it:** Daniel's Minecraft launcher on `bridge` (1.9 GB
  of instances). Replaces the AUR's `freesmlauncher-bin`, which repackaged
  upstream's portable build under `/opt`.
- **Source:** upstream's release source tarball
  `https://github.com/FreesmTeam/FreesmLauncher/releases/download/2.3.1/FreesmLauncher-2.3.1.tar.gz`,
  sha256 `6fe070f9d6211b7dedeaeef4309d4014c15e66f8b6573da5652f070cb2c6dd62`
  (the same hash the AUR pins). It is a source archive that also carries
  the git submodules (libnbtplusplus and others), uploaded by upstream's
  release workflow. FreesmLauncher is a fork of Prism Launcher by
  FreesmTeam.
- **Starting recipe:** AUR `freesmlauncher` (aur.git `fade773`), maintained
  by a FreesmTeam member and an Arch packager. CMake with upstream's
  options, `ctest`, no install script. depot keeps it as is apart from the
  Maintainer line and optdepends.
- **Build:** CMake and Ninja with makepkg's flags (`!lto` as the AUR has
  it). Java helpers (`JavaCheck`, `NewLaunch`) are compiled from source with
  JDK 17. No downloads during the build. The updater is not built
  (`Launcher_BUILD_UPDATER` needs `Launcher_BUILD_ARTIFACT`, unset).
- **Upstream code read:** the CMake files and install rules, and the
  network endpoints in `CMakeLists.txt`: Microsoft and Mojang sign-in,
  `meta.freesmlauncher.org` for version metadata, Prism's FML library
  mirror and wiki, and mod platforms when used. The Java downloader fetches
  a Java runtime into the user's data directory when asked. All of that
  runs as the user, as with the AUR copy. The only `.jar` files in the
  source are test fixtures under `tests/testdata`; no prebuilt binaries.
- **Allowed paths:** `allow` grants the menu entry, the two icons, the
  AppStream metadata, the MIME type (pacman's shared-mime-info hook runs
  `update-mime-database` on it) and `usr/share/FreesmLauncher/` for the Java
  helpers and `qtlogging.ini`, and its Qt logging categories file. Daniel
  approved desktop files and icons for
  this package on 2026-11-03. Nothing here runs as root.
- **Install:** no install script, no units, no setuid files.
- **Upstream status:** active (release 2.3.1 on 2026-09-29), same team.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
