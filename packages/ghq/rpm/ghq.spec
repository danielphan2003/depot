# Plain `go build` with upstream's go.sum pinning the modules, which come
# from proxy.golang.org during the build. The binary is static.
%global debug_package %{nil}

Name:           ghq
Version:        1.12.0
Release:        1%{?dist}
Summary:        Remote repository management made easy
License:        MIT
URL:            https://github.com/x-motemen/ghq
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  golang >= 1.26

%description
ghq clones repositories into a tree ordered by host and path, and lists and finds them. Built by depot from the upstream release.

%prep
%autosetup -n ghq-%{version}

%build
export GOTOOLCHAIN=local CGO_ENABLED=0
export GOPATH=%{_builddir}/.gopath GOCACHE=%{_builddir}/.gocache
export GOFLAGS="-mod=readonly -modcacherw -trimpath"
go mod download
go build -ldflags "-s -w -X main.revision=v%{version}" -o ghq .

%install
install -Dm755 ghq -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.adoc
%{_bindir}/ghq

%changelog
* Fri Nov 06 2026 depot <noreply@github.com> - 1.12.0-1
- Upstream release 1.12.0.

* Tue Nov 03 2026 depot <noreply@github.com> - 1.11.2-1
- Upstream release 1.11.2.
