# Repackages upstream's release binary for x86_64; nothing is compiled (AUDIT.md).
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           zellij
Version:        0.46.0
Release:        1%{?dist}
Summary:        Terminal workspace and multiplexer
License:        MIT
URL:            https://github.com/zellij-org/zellij
Source0:        https://github.com/zellij-org/zellij/releases/download/v%{version}/zellij-x86_64-unknown-linux-musl.tar.gz

ExclusiveArch:  x86_64

%description
A terminal multiplexer with layouts, floating panes and a plugin system. Repackaged by depot from the upstream release binary.

%prep
%setup -q -c -n zellij-%{version}

%build

%install
install -Dm755 zellij -t %{buildroot}%{_bindir}

%files
%{_bindir}/zellij

%changelog
* Thu Nov 12 2026 depot <noreply@github.com> - 0.46.0-1
- Upstream release 0.46.0.

* Fri Nov 06 2026 depot <noreply@github.com> - 0.45.1-1
- Upstream release 0.45.1.
