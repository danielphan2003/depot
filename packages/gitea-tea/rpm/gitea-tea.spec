# Plain `go build` with upstream's go.sum pinning the modules, which come
# from proxy.golang.org during the build. The binary is static.
%global debug_package %{nil}

Name:           gitea-tea
Version:        0.16.0
Release:        1%{?dist}
Summary:        Command-line client for Gitea servers
License:        MIT
URL:            https://gitea.com/gitea/tea
# The Go module proxy's copy of the tag; see package.env.
Source0:        https://proxy.golang.org/gitea.dev/tea/@v/v%{version}.zip

ExclusiveArch:  x86_64
BuildRequires:  golang >= 1.26
BuildRequires:  unzip

%description
tea, the official Gitea CLI: issues, pull requests, releases and repositories from the terminal. Named gitea-tea, as on Debian, where tea is an unrelated editor. Built by depot from the upstream release.

%prep
%autosetup -n gitea.dev/tea@v%{version}

%build
export GOTOOLCHAIN=local CGO_ENABLED=0
export GOPATH=%{_builddir}/.gopath GOCACHE=%{_builddir}/.gocache
export GOFLAGS="-mod=readonly -modcacherw -trimpath"
go mod download
go build -ldflags "-s -w -X gitea.dev/tea/modules/version.Version=%{version} -X gitea.dev/tea/modules/version.SDK=$(go list -f "{{.Version}}" -m gitea.dev/sdk)" -o tea .

%install
install -Dm755 tea -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.md
%{_bindir}/tea

%changelog
* Tue Nov 03 2026 depot <noreply@github.com> - 0.16.0-1
- Upstream release 0.16.0.
