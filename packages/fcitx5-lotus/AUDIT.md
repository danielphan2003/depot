# fcitx5-lotus: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 6.0.4-2 (2026-11-09)

- **Change:** upstream's release binary instead of a source build (Daniel,
  2026-11-09: a package whose upstream binary carries a GitHub attestation
  uses that binary). The version, and so the upstream code, is the one
  audited in 6.0.4-1 below.
- **Source:**
  `https://github.com/LotusInputMethod/fcitx5-lotus/releases/download/v6.0.4/fcitx5-lotus-v6.0.4-x86_64-archlinux.tar.zst`,
  sha256 `23c04d0a366346057fab5cc59d77b255b37319d209032c2d306d24f4368a9c52`:
  upstream's Arch build, a tree of `etc/` and `usr/`.
- **Attestation:** SLSA build provenance (`https://slsa.dev/provenance/v1`),
  signed for
  `LotusInputMethod/fcitx5-lotus/.github/workflows/build-and-release.yml`
  run for `refs/tags/v6.0.4`. `lint.sh` checks it with `gh attestation
  verify --signer-workflow ... --source-ref ...` on every run. Unlike a
  release attestation, this proves upstream's own workflow built the file
  from that tag.
- **Contents:** only `usr/` is packaged, the same files the source build
  installed (the paths in `allow`), plus the settings GUI's compiled
  `__pycache__` files (Python 3.14) and the license under
  `usr/share/licenses/fcitx5-lotus/`. The tarball's `etc/runit` and
  `etc/init.d` services stay out, as before, and there is still no install
  script. `check_package` enforces the paths.
- **Binary:** `liblotus.so` and `fcitx5-lotus-server` link Arch's fcitx5,
  libinput, libudev, libevdev, libnotify, GLib and D-Bus, as built by
  upstream on 2026-10-31. The runtime `depends` are unchanged. depot no
  longer rebuilds them against today's libraries, so a soname bump in one of
  them shows up in the canary, and is fixed by an upstream release or a
  return to the source build.
- **Allowed paths:** unchanged (Daniel, 2026-11-03; see 6.0.4-1).
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-09.

## 6.0.4-1 (2026-11-03)

- **Why depot ships it:** Daniel's Vietnamese input method on `bridge`
  (`DefaultIM=lotus`, mode "Uinput (Smooth)"). Replaces the AUR's
  `fcitx5-lotus-bin`. Arch ships fcitx5-bamboo and fcitx5-unikey, not Lotus.
- **Source:** upstream tag tarball
  `https://github.com/LotusInputMethod/fcitx5-lotus/archive/refs/tags/v6.0.4.tar.gz`,
  sha256 `01aab5d583d801e577c8985aa00f1bb3a8ca346a6769bd0f439ef675d2d6b89c`.
  The LotusInputMethod organization is the author's (Nguyen Hoang Ky); Lotus
  is the successor of his fcitx5-vmk.
- **Starting recipe:** AUR `fcitx5-lotus` (aur.git `8c40b0a`) and
  `fcitx5-lotus-bin` (`c91edc7`), both by the upstream author. The source
  one clones the tag unpinned (`sha256sums=SKIP`) and splits out OpenRC and
  runit packages; both carry `fcitx5-lotus.install`, whose `post_install`
  runs `udevadm control --reload-rules; udevadm trigger` and prints setup
  hints. depot builds the pinned tarball with CMake, runs upstream's tests,
  and drops the install script: systemd's pacman hooks reload udev rules and
  apply sysusers.d when those files change.
- **Build:** CMake and Ninja with makepkg's flags; no downloads (no
  FetchContent or ExternalProject). The settings GUI is Python, byte-compiled
  at install.
- **Upstream code read:** the server (`server/`, 750 lines) is the part
  that matters. It listens on two abstract Unix sockets and accepts a peer
  only if `SO_PEERCRED` gives the target user's UID and
  `readlink(/proc/<pid>/exe)` is exactly `/usr/bin/fcitx5` (it needs
  `CAP_SYS_PTRACE` to read another user's `/proc/<pid>/exe`). It injects
  only a fixed set of keys through uinput: Backspace, Left, Delete, Pause and
  Shift, never arbitrary text. It reads keyboards with libinput only to know
  whether Shift is physically held. `CAP_SYS_NICE` is for `setpriority(-10)`
  and pinning to a performance core. The addon (`src/`) runs `dbus-send` and
  `gsettings` through `popen` to read the colour scheme, and reads
  `/proc/<pid>/comm` of the focused app for per-app rules. No network
  access anywhere; the only URL is the docs link in a notification.
- **Allowed paths:** `allow` grants the addon's fcitx5 files, the settings
  GUI, its menu entry, icons and translations, and four root-level files for
  the server, which Daniel approved after this review:
  `fcitx5-lotus-server@.service` (runs the server as `uinput_proxy`, group
  `input`, with `CAP_SYS_NICE CAP_SYS_PTRACE`), `sysusers.d/lotus.conf`
  (creates `uinput_proxy` and adds it to `input`), `udev/rules.d/99-lotus.rules`
  (`setfacl -m u:uinput_proxy:rw /dev/uinput`) and `modules-load.d` (loads
  `uinput`). These are the same files `fcitx5-lotus-bin` installed on
  `bridge`.
- **Risk accepted:** the server can read every keyboard (the `input`
  group) and type into any window, beneath Wayland's input isolation. A
  process running as Daniel that could control `/usr/bin/fcitx5` could have
  it type those five keys anywhere. `kernel.yama.ptrace_scope=1` on `bridge`
  stops a sibling process from attaching to fcitx5. This was already the
  case with the AUR package.
- **Install:** no install script, no setuid files, no file capabilities;
  the unit grants the capabilities when systemd starts it.
- **Upstream status:** active, same owner, not archived.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
