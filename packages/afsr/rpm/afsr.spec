# Upstream's static release binary, repackaged; nothing is compiled. lint.sh
# checks GitHub's release attestation for the pinned file (../AUDIT.md).
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           afsr
Version:        2.1.1
Release:        1%{?dist}
Summary:        Unpack, modify and repack Android ext4 and erofs filesystem images reproducibly
License:        GPL-2.0-or-later
URL:            https://github.com/chenxiaolong/afsr
Source0:        %{url}/releases/download/v%{version}/afsr-%{version}-x86_64-unknown-linux-gnu.zip

ExclusiveArch:  x86_64
BuildRequires:  unzip

%description
Unpacks ext4 and erofs filesystem images to a directory and metadata file, and packs them back byte-for-byte reproducibly, in userspace. Repackaged by depot from the upstream release binary.

%prep
%setup -q -c

%build

%install
install -Dm755 afsr -t %{buildroot}%{_bindir}

%files
%{_bindir}/afsr

%changelog
* Sat Nov 14 2026 depot <noreply@github.com> - 2.1.1-1
- Upstream release 2.1.1: the attested static release binary.
