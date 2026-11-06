# Repackages upstream's release binary for x86_64; nothing is compiled (AUDIT.md).
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           nushell
Version:        0.116.1
Release:        1%{?dist}
Summary:        A new type of shell
License:        MIT
URL:            https://github.com/nushell/nushell
Source0:        https://github.com/nushell/nushell/releases/download/%{version}/nu-%{version}-x86_64-unknown-linux-gnu.tar.gz

ExclusiveArch:  x86_64

%description
A shell whose pipelines carry structured data (tables, records, lists) instead of text. Repackaged by depot from the upstream release binary.

%prep
%autosetup -n nu-%{version}-x86_64-unknown-linux-gnu

%build

%install
install -Dm755 nu -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.txt
%{_bindir}/nu

%changelog
* Fri Nov 06 2026 depot <noreply@github.com> - 0.116.1-1
- Upstream release 0.116.1.
