# run0-sudo-shim: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 1.4.2-1 (2026-11-03)

- **Why depot ships it:** it is `/usr/bin/sudo` on `bridge`. Every `sudo`
  becomes `run0`, which asks polkit, so each privileged command raises the
  desktop authorization prompt (factory `AGENTS.md`, Privilege boundary).
  Replaces the AUR's `run0-sudo-shim-git`. No distribution ships it.
- **Source:** upstream tag tarball
  `https://github.com/GrimmTheShrimp/run0-sudo-shim/archive/refs/tags/1.4.2.tar.gz`,
  sha256 `ddb7e16e95f8f2a3eba2d7cc489919e3a636586b93d41e113778ce3b8caf2f70`.
  Tag `1.4.2` is annotated and signed (GitHub shows it verified), by
  Grimmauld, and points at `9fa985d`, which is both `main` today and the
  commit the AUR `-git` package on `bridge` was built from
  (`1.4.2.r0.g9fa985d`). The account was renamed from `LordGrimmauld`
  (Cargo.toml's `repository`; GitHub redirects). 129 of 144 commits are the
  author's.
- **Starting recipe:** AUR `run0-sudo-shim-git` (aur.git `1446122`,
  maintainer `lynastral`). It builds the moving default branch with an
  unlocked `cargo build --release`, installs fish and bash completions (the
  bash one to a path missing its `/`), the man page, and the binary as
  `/usr/bin/sudo`, with `provides=sudo` and `conflicts=sudo`. No install
  script. depot pins the tag, builds `--frozen` from `Cargo.lock` (27
  crates: clap and its dependencies, `users`), runs `cargo test`, and drops
  the completions.
- **Hardening:** `src/common.rs` takes `run0`, `true` and
  `polkit-stdin-agent` from compile-time environment variables and falls
  back to bare names, looked up in `$PATH`. depot compiles in
  `/usr/bin/run0` and `/usr/bin/true`, so a `run0` planted earlier in
  `$PATH` cannot be picked up. `polkit-stdin-agent` (only for `sudo -S`)
  stays a bare name: Arch does not ship it, so `sudo -S` fails as before.
- **Upstream code read:** all of it, 1073 lines. `main.rs` parses sudo's
  arguments with clap, builds a `run0` command line and `exec`s it; it never
  touches credentials, files or the network, and it is not setuid: `run0`
  and polkit make every decision. `sudo/mod.rs` maps the options:
  `--user`/`--group` to `--user=`/`--group=`, `-D` to `--chdir=`, `-i` and
  `-s` to `--via-shell`, `-n` to `--no-ask-password`, `-C` and `-T` to
  `LimitNOFILE` and `RuntimeMaxSec` properties, and `-E` to `--setenv=` for
  each preserved variable (without a list it preserves all but a blocklist
  and warns that this is insecure). `--edit`, `--chroot`, `--host`,
  `--background` and `--preserve-groups` are refused; `--askpass` and
  `--prompt` are ignored with a warning. `build.rs` only renders the man page
  and completions from the clap definitions.
- **Allowed paths:** none beyond the defaults (`/usr/bin/sudo`, `sudo.8`,
  docs). `allow` grants the only relations any depot package declares,
  `provides sudo` and `conflicts sudo`, which Daniel approved on 2026-11-03;
  `check_package` refuses any other, and every relation on Debian and
  Fedora.
- **Install:** no install script, not setuid, no capabilities.
- **Upstream status:** active (last release 2026-07-01), same owner.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-03.
