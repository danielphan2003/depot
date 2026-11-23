# cargo build --locked: crates come from crates.io, pinned by upstream's
# Cargo.lock, with Fedora's Rust and C flags (hardening, PIE). libgit2 is
# Fedora's, not the copy vendored in libgit2-sys, so it gets Fedora's fixes.
%global debug_package %{nil}

Name:           radicle
Version:        1.10.3
Release:        1%{?dist}
Summary:        Peer-to-peer code collaboration stack built on Git
License:        MIT OR Apache-2.0
URL:            https://radicle.dev
Source0:        https://files.radicle.dev/releases/%{version}/heartwood-%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  cargo
BuildRequires:  cargo-rpm-macros
BuildRequires:  gcc
BuildRequires:  pkgconfig(libgit2)
BuildRequires:  pkgconfig(zlib)
BuildRequires:  rubygem-asciidoctor
# rad refuses to run without git, and git-remote-rad is a git remote helper
Requires:       git-core

%description
Radicle's command-line tool (rad), its node (radicle-node) and the git
remote helper for rad:// remotes (git-remote-rad). Built by depot from the
upstream release.

%prep
%autosetup -c -n heartwood-%{version}

%build
%set_build_flags
export RUSTFLAGS="%{build_rustflags}" CARGO_HOME=%{_builddir}/.cargo
# build.rs asks git for these when they are unset; the tarball is not a git
# repository, so set them here. The commit is not in the tarball.
export RADICLE_VERSION=%{version} GIT_HEAD=unknown LIBGIT2_NO_VENDOR=1
cargo build --locked --release --bins \
  -p radicle-cli -p radicle-node -p radicle-remote-helper
# upstream's scripts/build-man-pages.sh only wraps this loop, and would try to
# install asciidoctor itself if it were missing
mkdir -p target/man
for page in *.1.adoc; do
  asciidoctor --doctype manpage --backend manpage --destination-dir target/man "$page"
done

%install
install -Dm755 target/release/rad target/release/radicle-node \
  target/release/git-remote-rad -t %{buildroot}%{_bindir}
install -Dm644 target/man/*.1 -t %{buildroot}%{_mandir}/man1

%files
%license LICENSE-MIT LICENSE-APACHE
%doc README.md CHANGELOG.md
%{_bindir}/rad
%{_bindir}/radicle-node
%{_bindir}/git-remote-rad
%{_mandir}/man1/*.1*

%changelog
* Tue Nov 24 2026 depot <noreply@github.com> - 1.10.3-1
- Upstream release 1.10.3.
