# cargo build --locked: crates come from crates.io, pinned by upstream's
# Cargo.lock, with Fedora's Rust flags (hardening, PIE). build.rs writes the
# man page from dpibreak.1.in; the tag also carries the rendered dpibreak.1.
# The package installs no unit: the machine's own unit runs the binary as root.
%global debug_package %{nil}

Name:           dpibreak
Version:        0.6.2
Release:        1%{?dist}
Summary:        System-wide DPI circumvention with minimal configuration
License:        GPL-3.0-or-later
URL:            https://github.com/dilluti0n/dpibreak
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  cargo
BuildRequires:  cargo-rpm-macros
BuildRequires:  gcc
Requires:       nftables

%description
Fragments the TLS ClientHello of outgoing HTTPS connections so that stateless deep packet inspection equipment cannot read the server name. It registers its own nftables rules and an NFQUEUE on startup, removes them on exit, and needs root. Built by depot from the upstream release.

%prep
%autosetup -n dpibreak-%{version}

%build
export RUSTFLAGS="%{build_rustflags}" CARGO_HOME=%{_builddir}/.cargo
cargo build --locked --release

%install
install -Dm755 target/release/dpibreak -t %{buildroot}%{_bindir}
install -Dm644 dpibreak.1 -t %{buildroot}%{_mandir}/man1

%files
%license COPYING
%doc README.md
%{_bindir}/dpibreak
%{_mandir}/man1/dpibreak.1*

%changelog
* Mon Nov 09 2026 depot <noreply@github.com> - 0.6.2-1
- Upstream release 0.6.2.
