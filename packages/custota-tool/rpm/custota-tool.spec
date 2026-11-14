# Upstream's static release binary, repackaged; nothing is compiled. lint.sh
# checks GitHub's release attestation for the pinned file (../AUDIT.md).
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           custota-tool
Version:        6.10
Release:        1%{?dist}
Summary:        Generate and sign update metadata for the Custota Android OTA updater
License:        GPL-3.0-only
URL:            https://github.com/chenxiaolong/Custota
Source0:        %{url}/releases/download/v%{version}/custota-tool-%{version}-x86_64-unknown-linux-gnu.zip

ExclusiveArch:  x86_64
BuildRequires:  unzip

%description
Generates and signs the update metadata (csig and update info) that the Custota OTA updater app reads. Repackaged by depot from the upstream release binary.

%prep
%setup -q -c

%build

%install
install -Dm755 custota-tool -t %{buildroot}%{_bindir}

%files
%{_bindir}/custota-tool

%changelog
* Sat Nov 14 2026 depot <noreply@github.com> - 6.10-1
- Fedora 44 target: upstream's attested static release binary.
