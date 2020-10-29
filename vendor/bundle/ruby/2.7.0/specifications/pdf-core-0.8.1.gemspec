# -*- encoding: utf-8 -*-
# stub: pdf-core 0.8.1 ruby lib

Gem::Specification.new do |s|
  s.name = "pdf-core".freeze
  s.version = "0.8.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregory Brown".freeze, "Brad Ediger".freeze, "Daniel Nelson".freeze, "Jonathan Greenberg".freeze, "James Healy".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDcDCCAligAwIBAgIBATANBgkqhkiG9w0BAQUFADA/MQ0wCwYDVQQDDARhbGV4\nMRkwFwYKCZImiZPyLGQBGRYJcG9pbnRsZXNzMRMwEQYKCZImiZPyLGQBGRYDb25l\nMB4XDTE4MDQyNzE5NTkyNloXDTE5MDQyNzE5NTkyNlowPzENMAsGA1UEAwwEYWxl\neDEZMBcGCgmSJomT8ixkARkWCXBvaW50bGVzczETMBEGCgmSJomT8ixkARkWA29u\nZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM85Us8YQr55o/rMl+J+\nula89ODiqjdc0kk+ibzRLCpfaFUJWxEMrhFiApRCopFDMeGXHXjBkfBYsRMFVs0M\nZfe6rIKdNZQlQqHfJ2JlKFek0ehX81buGERi82wNwECNhOZu9c6G5gKjRPP/Q3Y6\nK6f/TAggK0+/K1j1NjT+WSVaMBuyomM067ejwhiQkEA3+tT3oT/paEXCOfEtxOdX\n1F8VFd2MbmMK6CGgHbFLApfyDBtDx+ydplGZ3IMZg2nPqwYXTPJx+IuRO21ssDad\ngBMIAvL3wIeezJk2xONvhYg0K5jbIQOPB6zD1/9E6Q0LrwSBDkz5oyOn4PRZxgZ/\nOiMCAwEAAaN3MHUwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0OBBYEFE+A\njBJVt6ie5r83L/znvqjF1RuuMB0GA1UdEQQWMBSBEmFsZXhAcG9pbnRsZXNzLm9u\nZTAdBgNVHRIEFjAUgRJhbGV4QHBvaW50bGVzcy5vbmUwDQYJKoZIhvcNAQEFBQAD\nggEBAIAbB2aGarAHVCU9gg7Se3Rf2m97uZrSG+LCe8h5x36ZtjxARb6cyBPxoX4C\nTsy3MAgtj2thAoke++/c+XRCeXzzVMDxq3KEK7FONiy3APdHXfygN9iFjnN/K+Nv\n7yKfaocMWSlBlyj0k4r76neyoIgFHHjcnhS8EMst+UR9iUwFibAlVylu88hvnnK0\nfD6AgoHJro0u+R/P++J4dKC5wOD4gHGnq694kAdY/3rtRvorLtOJm+pHZSKe/9Je\nCWt9UspdQDfg95fK56I9NFeV+LrQ5Cj866DCeH25SFbgK9acS7lw4uOLVu/9QWhZ\notbeukAemPO8HXWM/JCgkR6BaPE=\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2018-04-28"
  s.description = "PDF::Core is used by Prawn to render PDF documents".freeze
  s.email = ["gregory.t.brown@gmail.com".freeze, "brad@bradediger.com".freeze, "dnelson@bluejade.com".freeze, "greenberg@entryway.net".freeze, "jimmy@deefa.com".freeze]
  s.homepage = "http://prawn.majesticseacreature.com".freeze
  s.licenses = ["PRAWN".freeze, "GPL-2.0".freeze, "GPL-3.0".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "PDF::Core is used by Prawn to render PDF documents".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<pdf-inspector>.freeze, ["~> 1.1.0"])
    s.add_development_dependency(%q<pdf-reader>.freeze, ["~> 1.2"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.55"])
    s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 1.25"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<pdf-inspector>.freeze, ["~> 1.1.0"])
    s.add_dependency(%q<pdf-reader>.freeze, ["~> 1.2"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.55"])
    s.add_dependency(%q<rubocop-rspec>.freeze, ["~> 1.25"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
  end
end
