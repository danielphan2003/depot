# cargo build --locked: crates come from crates.io, pinned by upstream's
# Cargo.lock, with Fedora's Rust flags (hardening, PIE).
%global debug_package %{nil}

Name:           starship
Version:        1.27.0
Release:        1%{?dist}
Summary:        Minimal, fast and customizable prompt for any shell
License:        ISC
URL:            https://github.com/starship/starship
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  cargo
BuildRequires:  cargo-rpm-macros
BuildRequires:  gcc

%description
A cross-shell prompt that shows the git, language and environment context of the current directory. Built by depot from the upstream release.

%prep
%autosetup -n starship-%{version}

%build
export RUSTFLAGS="%{build_rustflags}" CARGO_HOME=%{_builddir}/.cargo
cargo build --locked --release 

%install
install -Dm755 target/release/starship -t %{buildroot}%{_bindir}


%files
%license LICENSE
%doc README.md
%{_bindir}/starship


%changelog
* Tue Nov 03 2026 depot <noreply@github.com> - 1.27.0-1
- Upstream release 1.27.0.
