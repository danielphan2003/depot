# As ../arch/PKGBUILD: `go generate ./cmd/...`, then a static build with the
# `release` tag. Modules come from proxy.golang.org, pinned by upstream's go.sum.
%global debug_package %{nil}

Name:           carapace
Version:        1.8.2
Release:        1%{?dist}
Summary:        Multi-shell multi-command argument completer
License:        MIT
URL:            https://github.com/carapace-sh/carapace-bin
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  golang >= 1.26

%description
Completions for many commands in bash, zsh, fish, nushell, elvish and other
shells. Built by depot from the upstream release.

%prep
%autosetup -n carapace-bin-%{version}

%build
export GOTOOLCHAIN=local CGO_ENABLED=0
export GOPATH=%{_builddir}/.gopath GOCACHE=%{_builddir}/.gocache
export GOFLAGS="-mod=readonly -modcacherw -trimpath"
go mod download
(cd cmd/carapace && go generate ./...)
go build -tags release -ldflags "-s -w -X main.version=%{version}" -o carapace ./cmd/carapace

%install
install -Dm755 carapace -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.md
%{_bindir}/carapace

%changelog
* Tue Nov 03 2026 depot <noreply@github.com> - 1.8.2-1
- Upstream release 1.8.2.
