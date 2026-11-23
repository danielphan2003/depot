# cargo build --locked: crates come from crates.io, pinned by upstream's
# Cargo.lock, with Fedora's Rust and C flags (hardening, PIE). libgit2 is
# Fedora's, not the copy vendored in libgit2-sys, so it gets Fedora's fixes.
%global debug_package %{nil}

Name:           radicle-ci-broker
Version:        0.32.1
Release:        1%{?dist}
Summary:        CI broker for repositories on a Radicle node
License:        MIT OR Apache-2.0
URL:            https://radicle.dev
Source0:        https://static.crates.io/crates/radicle-ci-broker/radicle-ci-broker-%{version}.crate

ExclusiveArch:  x86_64
BuildRequires:  cargo
BuildRequires:  cargo-rpm-macros
BuildRequires:  gcc
BuildRequires:  pkgconfig(libgit2)
BuildRequires:  pkgconfig(zlib)
# the broker hands jobs to adapters, and upstream's Debian package depends on
# git for them
Requires:       git-core

%description
The Radicle CI broker watches a local Radicle node for events, filters them
and runs the configured CI adapters for the repositories that pass. cibtool
inspects and triggers the broker's queue and reports. Built by depot from the
upstream release; the node and an adapter such as radicle-ci-ambient are
separate packages, and factory supplies the user unit.

%prep
# The source is a crates.io .crate, a gzipped tar that rpm does not unpack
# itself.
%setup -q -T -c -n %{name}-%{version}
tar -xzf %{SOURCE0} --strip-components=1

%build
%set_build_flags
export RUSTFLAGS="%{build_rustflags}" CARGO_HOME=%{_builddir}/.cargo
# upstream's build.rs asks git for the commit id; the crate carries no git
# checkout, so the version prints @unknown. It does not use the network.
export LIBGIT2_NO_VENDOR=1
cargo build --locked --release --bin cib --bin cibtool

%install
install -Dm755 target/release/cib target/release/cibtool -t %{buildroot}%{_bindir}
install -Dm644 cib.1 cibtool.1 -t %{buildroot}%{_mandir}/man1

%files
%license LICENSE-MIT LICENSE-APACHE
%doc README.md NEWS.md
%{_bindir}/cib
%{_bindir}/cibtool
%{_mandir}/man1/cib.1*
%{_mandir}/man1/cibtool.1*

%changelog
* Tue Nov 24 2026 depot <noreply@github.com> - 0.32.1-1
- Upstream release 0.32.1.
