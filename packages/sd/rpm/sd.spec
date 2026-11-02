# cargo build --locked: crates come from crates.io, pinned by upstream's
# Cargo.lock, with Fedora's Rust flags (hardening, PIE).
%global debug_package %{nil}

Name:           sd
Version:        1.1.0
Release:        1%{?dist}
Summary:        Intuitive find and replace on the command line
License:        MIT
URL:            https://github.com/chmln/sd
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  cargo
BuildRequires:  cargo-rpm-macros
BuildRequires:  gcc

%description
sd is a find-and-replace tool with plain regular expressions and string literals, a simpler sed s///. Built by depot from the upstream release.

%prep
%autosetup -n sd-%{version}

%build
export RUSTFLAGS="%{build_rustflags}" CARGO_HOME=%{_builddir}/.cargo
cargo build --locked --release -p sd-cli

%install
install -Dm755 target/release/sd -t %{buildroot}%{_bindir}
install -Dm644 gen/sd.1 -t %{buildroot}%{_mandir}/man1

%files
%license LICENSE
%doc README.md
%{_bindir}/sd
%{_mandir}/man1/sd.1*

%changelog
* Tue Nov 03 2026 depot <noreply@github.com> - 1.1.0-1
- Upstream release 1.1.0.
