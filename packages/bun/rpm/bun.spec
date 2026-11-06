# Repackages upstream's release binary for x86_64; nothing is compiled (AUDIT.md).
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           bun
Version:        1.4.4
Release:        1%{?dist}
Summary:        JavaScript runtime, package manager and bundler
License:        MIT
URL:            https://github.com/oven-sh/bun
Source0:        https://github.com/oven-sh/bun/releases/download/bun-v%{version}/bun-linux-x64.zip

ExclusiveArch:  x86_64
BuildRequires:  unzip

%description
An all-in-one toolkit for JavaScript and TypeScript: runtime, package manager, test runner and bundler. Repackaged by depot from the upstream release binary.

%prep
%autosetup -n bun-linux-x64

%build

%install
install -Dm755 bun -t %{buildroot}%{_bindir}
cat >%{buildroot}%{_bindir}/bunx <<'EOF'
#!/bin/sh
# bunx is `bun x`. Upstream links it to bun, but depot packages carry no links.
exec /usr/bin/bun x "$@"
EOF
chmod 755 %{buildroot}%{_bindir}/bunx

%files
%{_bindir}/bun
%{_bindir}/bunx

%changelog
* Fri Nov 06 2026 depot <noreply@github.com> - 1.4.4-1
- Upstream release 1.4.4.
