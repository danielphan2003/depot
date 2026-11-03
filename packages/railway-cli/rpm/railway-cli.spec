# cargo build --locked: crates come from crates.io, pinned by upstream's
# Cargo.lock, with Fedora's Rust flags (hardening, PIE). Named railway-cli to
# match the Arch package; the binary is /usr/bin/railway.
%global debug_package %{nil}

Name:           railway-cli
Version:        5.71.0
Release:        1%{?dist}
Summary:        Railway command-line client
License:        MIT
URL:            https://github.com/railwayapp/cli
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  cargo
BuildRequires:  cargo-rpm-macros
BuildRequires:  gcc

%description
Command-line client for Railway: link a project, deploy, read logs, and manage variables and services. Built by depot from the upstream release.

%prep
%autosetup -n cli-%{version}

%build
export RUSTFLAGS="%{build_rustflags}" CARGO_HOME=%{_builddir}/.cargo
cargo build --locked --release

%install
install -Dm755 target/release/railway -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.md
%{_bindir}/railway

%changelog
* Tue Nov 03 2026 depot <noreply@github.com> - 5.71.0-1
- Upstream release 5.71.0.
