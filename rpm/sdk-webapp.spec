Name:       sdk-webapp

Summary:    Mer SDK manager
Version:    0
Release:    1
Group:      Development Platform/Platform SDK
License:    GPLv2+
URL:        https://github.com/sailfishos/sdk-webapp
Source0:    %{name}-%{version}.tar.bz2
Requires:   sdk-webapp-bundle >= 0.4.0
Requires:   sdk-webapp-customization >= 0.4.0-2
Requires:   sdk-utils >= 0.57
Requires:   sdk-register >= 0.4
BuildRequires:  systemd

%description
Allows web-based management of the Mer SDK. Adds toolchains, targets etc

%package mer
Summary:    Mer customization for SDK management web-application
Group:      Development Platform/Platform SDK
Requires:   %{name} = %{version}-%{release}
Provides:   sdk-webapp-customization

%description mer
Gives SDK manager its default mer-ish look

%package ts-manual
Summary:    Translation source
Group:      Development Platform/Platform SDK
Requires:   %{name} = %{version}-%{release}

%description ts-manual
Translations until pootle is done

%package ts-devel
Summary:    Translation source
Group:      Development Platform/Platform SDK
Requires:   %{name} = %{version}-%{release}

%description ts-devel
Translations for pootle

%prep
%setup -q -n %{name}-%{version}/%{name}

%build
make %{?_smp_mflags}

%install
rm -rf %{buildroot}
%make_install

mkdir -p %{buildroot}%{_unitdir}
cp systemd/%{name}.service %{buildroot}%{_unitdir}/

%preun
%systemd_preun %{name}.service

%post
%systemd_post %{name}.service

%postun
%systemd_postun_with_restart %{name}.service

%files
%defattr(-,root,root,-)
%defattr(-,mersdk,mersdk)
%{_libdir}/%{name}-bundle/config.ru
%{_libdir}/%{name}-bundle/*.rb
%{_unitdir}/%{name}.service
%{_libdir}/%{name}-bundle/views/default.sass
%{_libdir}/%{name}-bundle/views/*.haml
%{_libdir}/%{name}-bundle/public/*.js
%{_libdir}/%{name}-bundle/public/ttf
%{_libdir}/%{name}-bundle/public/css
%{_libdir}/%{name}-bundle/.sass-cache/
%dir %attr(1777,mersdk,mersdk) %{_libdir}/%{name}-bundle/config

%files mer
%defattr(-,root,root,-)
%defattr(-,mersdk,mersdk)
%config %{_libdir}/%{name}-bundle/config/providers.json
%{_libdir}/%{name}-bundle/views/index.sass
%{_libdir}/%{name}-bundle/public/images

%files ts-manual
%defattr(-,root,root,-)
%defattr(-,mersdk,mersdk)
%{_libdir}/%{name}-bundle/i18n/en.ts
%{_libdir}/%{name}-bundle/i18n/fi.ts
%{_libdir}/%{name}-bundle/i18n/zh_CN.ts

%files ts-devel
%defattr(-,root,root,-)
%defattr(-,mersdk,mersdk)
%{_libdir}/%{name}-bundle/i18n/en.ts
