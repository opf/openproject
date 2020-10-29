# -*- encoding: utf-8 -*-
# stub: ttfunk 1.6.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "ttfunk".freeze
  s.version = "1.6.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregory Brown".freeze, "Brad Ediger".freeze, "Daniel Nelson".freeze, "Jonathan Greenberg".freeze, "James Healy".freeze, "Cameron Dutro".freeze]
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDMjCCAhqgAwIBAgIBAjANBgkqhkiG9w0BAQsFADA/MQ0wCwYDVQQDDARhbGV4\nMRkwFwYKCZImiZPyLGQBGRYJcG9pbnRsZXNzMRMwEQYKCZImiZPyLGQBGRYDb25l\nMB4XDTE5MTIwMjEwMjAzNVoXDTIwMTIwMTEwMjAzNVowPzENMAsGA1UEAwwEYWxl\neDEZMBcGCgmSJomT8ixkARkWCXBvaW50bGVzczETMBEGCgmSJomT8ixkARkWA29u\nZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM85Us8YQr55o/rMl+J+\nula89ODiqjdc0kk+ibzRLCpfaFUJWxEMrhFiApRCopFDMeGXHXjBkfBYsRMFVs0M\nZfe6rIKdNZQlQqHfJ2JlKFek0ehX81buGERi82wNwECNhOZu9c6G5gKjRPP/Q3Y6\nK6f/TAggK0+/K1j1NjT+WSVaMBuyomM067ejwhiQkEA3+tT3oT/paEXCOfEtxOdX\n1F8VFd2MbmMK6CGgHbFLApfyDBtDx+ydplGZ3IMZg2nPqwYXTPJx+IuRO21ssDad\ngBMIAvL3wIeezJk2xONvhYg0K5jbIQOPB6zD1/9E6Q0LrwSBDkz5oyOn4PRZxgZ/\nOiMCAwEAAaM5MDcwCQYDVR0TBAIwADALBgNVHQ8EBAMCBLAwHQYDVR0OBBYEFE+A\njBJVt6ie5r83L/znvqjF1RuuMA0GCSqGSIb3DQEBCwUAA4IBAQBE9BhVReOpWN3A\nS5L3I9rCVg3aj5/7Z2K3Op6Q1VlCgv9UR+r8wqox9NxA94HAsmOexr5tmRVHO4WC\nnEZRHK9j4MzjKKChiRxLgWh78o/Mwvn2QT6cGCtUzfboWuVKACB5oJyAmfwomhUw\n4/zDsx6J4v1dDLy3vNu062uYbFLf94qRAo34r5cMt2Z3bC68zrbcRxfUE8fOudkt\nu8IGMi8WtDe3DkNUiV3rZ1XOdcg5q5vJye4wsy+TJ3733jrdqa+XnI7r8joFuJry\nNAnYg0X9IoxXQRCJn85h0SOQBU63TUfKDrERXDy0NLZT6sErDnpx84+ygqpxVAD+\n4qo2amfe\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2020-02-14"
  s.description = "Font Metrics Parser for the Prawn PDF generator".freeze
  s.email = ["gregory.t.brown@gmail.com".freeze, "brad@bradediger.com".freeze, "dnelson@bluejade.com".freeze, "greenberg@entryway.net".freeze, "jimmy@deefa.com".freeze, "camertron@gmail.com".freeze]
  s.homepage = "https://prawnpdf.org".freeze
  s.licenses = ["Nonstandard".freeze, "GPL-2.0".freeze, "GPL-3.0".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 2.4".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "TrueType Font Metrics Parser".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, ["~> 12"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5"])
    s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.68"])
    s.add_development_dependency(%q<rubocop-performance>.freeze, ["~> 1.1"])
    s.add_development_dependency(%q<rubocop-rspec>.freeze, ["~> 1.32"])
    s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
  else
    s.add_dependency(%q<rake>.freeze, ["~> 12"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.68"])
    s.add_dependency(%q<rubocop-performance>.freeze, ["~> 1.1"])
    s.add_dependency(%q<rubocop-rspec>.freeze, ["~> 1.32"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
  end
end
