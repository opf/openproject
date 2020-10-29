# -*- encoding: utf-8 -*-
# stub: pdf-inspector 1.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "pdf-inspector".freeze
  s.version = "1.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregory Brown".freeze, "Brad Ediger".freeze, "Daniel Nelson".freeze, "Jonathan Greenberg".freeze, "James Healy".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDcDCCAligAwIBAgIBATANBgkqhkiG9w0BAQUFADA/MQ0wCwYDVQQDDARhbGV4\nMRkwFwYKCZImiZPyLGQBGRYJcG9pbnRsZXNzMRMwEQYKCZImiZPyLGQBGRYDb25l\nMB4XDTE3MDEwNDExNDAzM1oXDTE4MDEwNDExNDAzM1owPzENMAsGA1UEAwwEYWxl\neDEZMBcGCgmSJomT8ixkARkWCXBvaW50bGVzczETMBEGCgmSJomT8ixkARkWA29u\nZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM85Us8YQr55o/rMl+J+\nula89ODiqjdc0kk+ibzRLCpfaFUJWxEMrhFiApRCopFDMeGXHXjBkfBYsRMFVs0M\nZfe6rIKdNZQlQqHfJ2JlKFek0ehX81buGERi82wNwECNhOZu9c6G5gKjRPP/Q3Y6\nK6f/TAggK0+/K1j1NjT+WSVaMBuyomM067ejwhiQkEA3+tT3oT/paEXCOfEtxOdX\n1F8VFd2MbmMK6CGgHbFLApfyDBtDx+ydplGZ3IMZg2nPqwYXTPJx+IuRO21ssDad\ngBMIAvL3wIeezJk2xONvhYg0K5jbIQOPB6zD1/9E6Q0LrwSBDkz5oyOn4PRZxgZ/\nOiMCAwEAAaN3MHUwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0OBBYEFE+A\njBJVt6ie5r83L/znvqjF1RuuMB0GA1UdEQQWMBSBEmFsZXhAcG9pbnRsZXNzLm9u\nZTAdBgNVHRIEFjAUgRJhbGV4QHBvaW50bGVzcy5vbmUwDQYJKoZIhvcNAQEFBQAD\nggEBAEmhsdVfgxHfXtOG6AP3qe7/PBjJPdUzNOkE/elj6TgpdvvJkOZ6QNyyqvpl\nCsoDWL0EXPM5pIETaj5z9iBRK9fAi8YNS3zckhBJwhR78cb4+MiCPIBC+iiGx5bw\nBFER2ASPeeY4uC0AHWHnURDLdxyZr+xp6pb/TitTAaCm18Kvkk1u60lOa4Jtdb+9\n2U1KICEBoX6UAzdT3N0nZ3VKq/vHVrvV2oePYCMIlNkghWp+VUE91OTBDMjnjjj8\nwxx1aB3kGoI0T6JXywKpPnzUt/qji/qpzCNiVJ0RZxzDHyZuL8NEoA9ORZnAIGiW\n5u3JK+T0toNEYkMuV6W8NU+gVyo=\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2017-03-17"
  s.description = "This library provides a number of PDF::Reader[0] based tools for use in testing\nPDF output.  Presently, the primary purpose of this tool is to support the\ntests found in Prawn[1], a pure Ruby PDF generation library.\n\nHowever, it may be useful to others, so we have made it available as a gem in\nits own right.\n\n[0] https://github.com/yob/pdf-reader\n[1] https://github.com/prawnpdf/prawn\n".freeze
  s.email = ["gregory.t.brown@gmail.com".freeze, "brad@bradediger.com".freeze, "dnelson77@gmail.com".freeze, "greenberg@entryway.net".freeze, "jimmy@deefa.com".freeze]
  s.extra_rdoc_files = ["CHANGELOG.md".freeze, "README.md".freeze]
  s.files = ["CHANGELOG.md".freeze, "README.md".freeze]
  s.homepage = "https://github.com/prawnpdf/pdf-inspector".freeze
  s.licenses = ["PRAWN".freeze, "GPL-2.0".freeze, "GPL-3.0".freeze]
  s.rdoc_options = ["--title".freeze, "PDF::Inspector".freeze, "--main".freeze, "README.md".freeze, "-q".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "A tool for analyzing PDF output".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<pdf-reader>.freeze, [">= 1.0", "< 3.0.a"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.46"])
    s.add_development_dependency(%q<yard>.freeze, [">= 0"])
  else
    s.add_dependency(%q<pdf-reader>.freeze, [">= 1.0", "< 3.0.a"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.46"])
    s.add_dependency(%q<yard>.freeze, [">= 0"])
  end
end
