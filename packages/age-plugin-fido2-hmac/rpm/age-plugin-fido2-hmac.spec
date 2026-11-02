# Plain `go build` with upstream's go.sum pinning the modules, as in
# ../arch/PKGBUILD. Modules come from proxy.golang.org during the build.
# rpm's dependency generator adds the libfido2 soname requirement.
%global debug_package %{nil}

Name:           age-plugin-fido2-hmac
Version:        0.5.0
Release:        1%{?dist}
Summary:        Age plugin to encrypt files with FIDO2 tokens using hmac-secret
License:        MIT
URL:            https://github.com/olastor/age-plugin-fido2-hmac
Source0:        %{url}/archive/refs/tags/v%{version}.tar.gz

ExclusiveArch:  x86_64
BuildRequires:  golang >= 1.24
BuildRequires:  gcc
BuildRequires:  libfido2-devel

%description
Plugin for age that encrypts and decrypts files with a FIDO2 security key,
using the hmac-secret extension. Built by depot from the upstream release.

%prep
%autosetup -n %{name}-%{version}

%build
export GOTOOLCHAIN=local
export GOPATH=%{_builddir}/.gopath GOCACHE=%{_builddir}/.gocache
export GOFLAGS="-buildmode=pie -trimpath -mod=readonly -modcacherw"
export CGO_CFLAGS="%{build_cflags}" CGO_CPPFLAGS="%{build_cflags}"
export CGO_CXXFLAGS="%{build_cxxflags}" CGO_LDFLAGS="%{build_ldflags}"
go mod download
go build -ldflags "-linkmode=external -X main.Version=v%{version}" \
  -o %{name} ./cmd/age-plugin-fido2-hmac

%check
export GOTOOLCHAIN=local
export GOPATH=%{_builddir}/.gopath GOCACHE=%{_builddir}/.gocache
export GOFLAGS="-mod=readonly -modcacherw"
go test ./...

%install
install -Dm755 %{name} -t %{buildroot}%{_bindir}

%files
%license LICENSE
%doc README.md docs/*.md
%{_bindir}/%{name}

%changelog
* Mon Nov 02 2026 depot <noreply@github.com> - 0.5.0-1
- Upstream release 0.5.0.
