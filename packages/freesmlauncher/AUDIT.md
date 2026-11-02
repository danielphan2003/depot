# freesmlauncher: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

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
  helpers and `qtlogging.ini`. Daniel approved desktop files and icons for
  this package on 2026-11-03. Nothing here runs as root.
- **Install:** no install script, no units, no setuid files.
- **Upstream status:** active (release 2.3.1 on 2026-09-29), same team.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
