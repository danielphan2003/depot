# cargo build --locked: crates come from crates.io, pinned by upstream's
# Cargo.lock, with Fedora's Rust flags (hardening, PIE). As in
# ../arch/PKGBUILD: no units, config or completions (../AUDIT.md).
%global debug_package %{nil}

Name:           dufs
Version:        0.47.0
Release:        1%{?dist}
Summary:        Static file server with uploads, search, access control and WebDAV
License:        MIT OR Apache-2.0
URL:            https://github.com/sigoden/dufs
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  cargo
BuildRequires:  cargo-rpm-macros
BuildRequires:  gcc

%description
A small static file server with uploads, search, access control and WebDAV. Built by depot from the upstream release.

%prep
%autosetup -n dufs-%{version}

%build
export RUSTFLAGS="%{build_rustflags}" CARGO_HOME=%{_builddir}/.cargo
cargo build --locked --release

%install
install -Dm755 target/release/dufs -t %{buildroot}%{_bindir}

%files
%license LICENSE-MIT LICENSE-APACHE
%doc README.md
%{_bindir}/dufs

%changelog
* Sat Nov 14 2026 depot <noreply@github.com> - 0.47.0-1
- Fedora 44 target.
