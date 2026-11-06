# Repackages upstream's release binary for x86_64; nothing is compiled (AUDIT.md).
%global debug_package %{nil}
%global _build_id_links none
%global __os_install_post %{nil}

Name:           nodejs
Version:        26.13.0
Release:        1%{?dist}
Summary:        JavaScript runtime built on V8
License:        MIT
URL:            https://github.com/nodejs/node
Source0:        https://nodejs.org/dist/v%{version}/node-v%{version}-linux-x64.tar.xz

ExclusiveArch:  x86_64

%description
Node.js, the newest release line that becomes LTS (even major), with npm. Repackaged by depot from the upstream release binary.

%prep
%autosetup -n node-v%{version}-linux-x64

%build

%install
install -Dm755 bin/node -t %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_prefix}/lib/nodejs
cp -a lib/node_modules %{buildroot}%{_prefix}/lib/nodejs/
cat >%{buildroot}%{_bindir}/npm <<'EOF'
#!/bin/sh
# Upstream links npm into lib/node_modules; depot packages carry no links.
exec /usr/bin/node /usr/lib/nodejs/node_modules/npm/bin/npm-cli.js "$@"
EOF
chmod 755 %{buildroot}%{_bindir}/npm
cat >%{buildroot}%{_bindir}/npx <<'EOF'
#!/bin/sh
exec /usr/bin/node /usr/lib/nodejs/node_modules/npm/bin/npx-cli.js "$@"
EOF
chmod 755 %{buildroot}%{_bindir}/npx
install -Dm644 share/man/man1/node.1 -t %{buildroot}%{_mandir}/man1

%files
%license LICENSE
%doc README.md
%{_bindir}/node
%{_bindir}/npm
%{_bindir}/npx
%{_prefix}/lib/nodejs
%{_mandir}/man1/node.1*

%changelog
* Fri Nov 06 2026 depot <noreply@github.com> - 26.13.0-1
- Upstream release 26.13.0.
