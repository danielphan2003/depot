# Upstream's static release binary, repackaged; nothing is compiled. lint.sh
# checks GitHub's release attestation for the pinned file (../AUDIT.md).
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           avbroot
Version:        3.39.1
Release:        1%{?dist}
Summary:        Patch Android A/B-style OTA images for root access
License:        GPL-3.0-only
URL:            https://github.com/chenxiaolong/avbroot
Source0:        %{url}/releases/download/v%{version}/avbroot-%{version}-x86_64-unknown-linux-gnu.zip

ExclusiveArch:  x86_64
BuildRequires:  unzip

%description
Patches Android A/B-style OTA images, signing them with the user's own AVB and OTA keys. Repackaged by depot from the upstream release binary.

%prep
%setup -q -c

%build

%install
install -Dm755 avbroot -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.md
%{_bindir}/avbroot

%changelog
* Sat Nov 14 2026 depot <noreply@github.com> - 3.39.1-1
- Fedora 44 target: upstream's attested static release binary.
