# Upstream's static (musl) release binary, repackaged; nothing is compiled.
# lint.sh checks GitHub's release attestation for the pinned file (AUDIT.md).
# Named railway-cli to match the Arch package; the binary is /usr/bin/railway.
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           railway-cli
Version:        5.71.0
Release:        2%{?dist}
Summary:        Railway command-line client
License:        MIT
URL:            https://github.com/railwayapp/cli
Source0:        %{url}/releases/download/v%{version}/railway-v%{version}-x86_64-unknown-linux-musl.tar.gz

ExclusiveArch:  x86_64

%description
Command-line client for Railway: link a project, deploy, read logs, and manage variables and services. Repackaged by depot from the upstream release binary.

%prep
%setup -q -c

%build

%install
install -Dm755 railway -t %{buildroot}%{_bindir}

%files
%{_bindir}/railway

%changelog
* Mon Nov 09 2026 depot <noreply@github.com> - 5.71.0-2
- Upstream's attested static release binary instead of a source build.

* Tue Nov 03 2026 depot <noreply@github.com> - 5.71.0-1
- Upstream release 5.71.0.
