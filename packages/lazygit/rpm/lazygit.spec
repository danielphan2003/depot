# Plain `go build` from upstream's vendor/ directory (checked against
# vendor/modules.txt and go.sum by the go command); no downloads. Static.
%global debug_package %{nil}

Name:           lazygit
Version:        0.66.3
Release:        1%{?dist}
Summary:        Simple terminal UI for git commands
License:        MIT
URL:            https://github.com/jesseduffield/lazygit
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  golang >= 1.26

%description
A terminal UI for git: staging, commits, branches, rebases and stashes. Built by depot from the upstream release.

%prep
%autosetup -n lazygit-%{version}

%build
export GOTOOLCHAIN=local CGO_ENABLED=0
export GOPATH=%{_builddir}/.gopath GOCACHE=%{_builddir}/.gocache
export GOFLAGS="-trimpath"
go build -mod=vendor -ldflags "-s -w -X main.version=%{version} -X main.buildSource=depot" -o lazygit .

%install
install -Dm755 lazygit -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.md
%{_bindir}/lazygit

%changelog
* Sun Nov 08 2026 depot <noreply@github.com> - 0.66.3-1
- Upstream release 0.66.3.

* Tue Nov 03 2026 depot <noreply@github.com> - 0.66.2-1
- Upstream release 0.66.2.
