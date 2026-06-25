%global debug_package %{nil}

Name:           omikuji
Version:        0.4.3
Release:        1%{?dist}
Summary:        Qt/QML based wine apps launcher for Linux

License:        GPL-3.0-or-later
URL:            https://github.com/reakjra/omikuji
Source0:        %{url}/archive/v%{version}/%{name}-%{version}.tar.gz

BuildRequires:  cargo
BuildRequires:  rust
BuildRequires:  cmake
BuildRequires:  gcc-c++
BuildRequires:  mold
BuildRequires:  pkgconf-pkg-config
BuildRequires:  protobuf-compiler
BuildRequires:  systemd-devel
BuildRequires:  openssl-devel
BuildRequires:  qt6-qtbase-devel
BuildRequires:  qt6-qtdeclarative-devel
BuildRequires:  qt6-qtsvg-devel
BuildRequires:  qt6-qtshadertools

Requires:       qt6-qtbase
Requires:       qt6-qtdeclarative
Requires:       qt6-qtsvg
Requires:       qt6-qt5compat
Requires:       qt6-qtwayland
Recommends:     vulkan-loader

%description
A Qt/QML based games and apps launcher for Linux with wine/flatpak/native runners, Epic Games (Legendary), GOG (gogdl) and Gacha stores.

%prep
%autosetup -n %{name}-%{version}

%build
cargo build --release --locked

%install
install -Dm0755 target/release/%{name} %{buildroot}%{_bindir}/%{name}
install -Dm0644 crates/omikuji/qml/icons/app.png %{buildroot}%{_datadir}/icons/hicolor/512x512/apps/io.github.reakjra.omikuji.png
install -Dm0644 packaging/io.github.reakjra.omikuji.desktop.in %{buildroot}%{_datadir}/applications/io.github.reakjra.omikuji.desktop
install -Dm0644 packaging/io.github.reakjra.omikuji.metainfo.xml %{buildroot}%{_datadir}/metainfo/io.github.reakjra.omikuji.metainfo.xml

%files
%license LICENSE
%{_bindir}/%{name}
%{_datadir}/applications/io.github.reakjra.omikuji.desktop
%{_datadir}/icons/hicolor/512x512/apps/io.github.reakjra.omikuji.png
%{_datadir}/metainfo/io.github.reakjra.omikuji.metainfo.xml

%changelog
* gio giu 25 2026 reakjra <reakjra@proton.me> - 0.4.3-1
- Fix GOG and Epic Games login page (+ DRY)

* Tue Jun 23 2026 reakjra <reakjra@proton.me> - 0.4.2-1
- "Open with Omikuji" picker for .exe files
- Theme fallbacks when the system color scheme is unknown
- RPM packaging
