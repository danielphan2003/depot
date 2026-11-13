# Upstream's static (musl) release binary, repackaged; nothing is compiled.
# lint.sh checks its SLSA build provenance for the pinned file (AUDIT.md).
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           atuin
Version:        18.24.8
Release:        1%{?dist}
Summary:        Magical shell history
License:        MIT
URL:            https://github.com/atuinsh/atuin
Source0:        %{url}/releases/download/v%{version}/atuin-x86_64-unknown-linux-musl.tar.gz

ExclusiveArch:  x86_64

%description
Replaces the shell's history with a searchable SQLite database that records the directory, exit code and duration of each command, and can sync it end to end encrypted. Repackaged by depot from the upstream release binary.

%prep
%autosetup -n atuin-x86_64-unknown-linux-musl

%build

%install
install -Dm755 atuin -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.md
%{_bindir}/atuin

%changelog
* Fri Nov 13 2026 depot <noreply@github.com> - 18.24.8-1
- Upstream release 18.24.8.

* Tue Nov 10 2026 depot <noreply@github.com> - 18.24.6-1
- Upstream release 18.24.6.
