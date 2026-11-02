# age-plugin-fido2-hmac: audit log

Newest first. Each entry records what was read, what was found, and who
read it. A version bump without an entry here does not get merged.

## 0.5.0-1 (2026-11-02)

- **Why depot ships it:** it lets age use a FIDO2 security key, and Arch,
  Debian and Fedora do not package it.
- **Source:** upstream tag tarball
  `https://github.com/olastor/age-plugin-fido2-hmac/archive/refs/tags/v0.5.0.tar.gz`,
  sha256 `dfdc7df03f444411bd531435f604b96c133350201e90b006e437829759d39883`.
  Its contents are identical to the source nixpkgs builds for 0.5.0
  (nixpkgs pins the hash of the unpacked tree).
- **Starting recipe:** AUR `age-plugin-fido2-hmac` (aur.git commit
  `78054a51`; the AUR account `oxy` is new: 3 packages, all submitted in the
  four days before the audit, 0 votes). Its PKGBUILD:
  - downloads only the upstream tarball above, pinned by sha256;
  - runs a plain `go build` with Arch's CGO flags, `-buildmode=pie
    -trimpath -mod=readonly`, so Go modules come from proxy.golang.org and
    are pinned by upstream's `go.sum`;
  - has no install script and no other downloads.
- **Changes in depot's copy:** Maintainer line; x86_64 only; `libfido2.so`
  added to `depends` so pacman records the soname (`libfido2.so=1-64`) and
  refuses a libfido2 upgrade that would break the plugin; `optdepends`
  dropped; `GOTOOLCHAIN=local` so Go never downloads a toolchain.
- **Debian and rpm recipes:** written for depot and kept the same as the
  PKGBUILD: same tarball, same `go build` flags, `go test ./...` in the
  check step. Each distribution's tooling computes the shared-library
  dependencies (`dh_shlibdeps`, rpm's generator).
- **Upstream dependencies (go.mod):** `filippo.io/age` v1.3.1,
  `github.com/olastor/go-libfido2` (upstream's own fork of the cgo libfido2
  binding), `golang.org/x/crypto` v0.45.0, `golang.org/x/sys` v0.38.0, and
  test-only `stretchr/testify`.
- **Runtime:** a single binary in `/usr/bin`, linked against libfido2 and
  glibc. No services, no scriptlets, nothing outside `/usr`.
- **Reviewed by:** Claude (Opus 5.5) for Daniel, 2026-11-02.
