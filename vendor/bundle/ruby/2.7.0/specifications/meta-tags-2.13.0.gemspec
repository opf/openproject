# -*- encoding: utf-8 -*-
# stub: meta-tags 2.13.0 ruby lib

Gem::Specification.new do |s|
  s.name = "meta-tags".freeze
  s.version = "2.13.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Dmytro Shteflyuk".freeze]
  s.bindir = "exe".freeze
  s.cert_chain = ["-----BEGIN CERTIFICATE-----\nMIIDODCCAiCgAwIBAgIBATANBgkqhkiG9w0BAQsFADAjMSEwHwYDVQQDDBhrcHVt\ndWsvREM9a3B1bXVrL0RDPWluZm8wHhcNMTgxMTE2MTgxOTIzWhcNMTkxMTE2MTgx\nOTIzWjAjMSEwHwYDVQQDDBhrcHVtdWsvREM9a3B1bXVrL0RDPWluZm8wggEiMA0G\nCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQC8NmK6GXPiE/q7PDbj7nNdw3pa8a6Q\nIDxLtc7kW95e1mh0TVgOE8kvGegGtRtjvhXVGTTFtZ+yMD/0DCfTM2oUQYk5oYpO\nZGrCfbNIdZauf4WYsnJtKOTrRoqFMwpL5PlBDKczB2y5lUmQs2HIsjQ0Q21wdKyy\n7tXiZPoCoJ+kH+b4/d4dcNvAXVnWgO2HoLW5oqWfqY5swkAHzwHLU+rlxxuHUqOy\n8/Y4hUSOXVIsxWxl3EapENm+QAfBRZn3L26hEb80CgSAp8m47Cj9DaSd7xoDtrIe\nRryRTj5NVZbq9p1/WRc5zxD9QhAEPjRa5ikbd+eWebIDpAKI0hpyC/9bAgMBAAGj\ndzB1MAkGA1UdEwQCMAAwCwYDVR0PBAQDAgSwMB0GA1UdDgQWBBT2uFRXNWDpVdbv\n+xBk8DAgJPGBPTAdBgNVHREEFjAUgRJrcHVtdWtAa3B1bXVrLmluZm8wHQYDVR0S\nBBYwFIESa3B1bXVrQGtwdW11ay5pbmZvMA0GCSqGSIb3DQEBCwUAA4IBAQB9bd46\np2C6r49hmuxMrIFRi05MS0Nze6GvlYvF5mb2+KS9YCLWLFb1G+0zttX51qVdO3nc\nuw1O5ku+Up47jv5ClyguHinCntFCA5hupyYkbpnFuURZE3QIY6UZQyJ2xuIPFfnR\nQ8sXb5/btWSNhKXx29TL35SkEH5fzPA90DljUPGp3lLEK0+7FQk0OkRVumdyanEE\nLUchqnAWHnNCdQhEhsnbYhSvG0NE2uzMWeUd6uDONYsRFNRXaRwj8tykWgKZvIod\nj0ZkOZOMk6hzny9+AnYZ7eiUqp/XX7Hn+hqtl/AebKhbFapnTu0n7KcfM0oDaLUr\nFc+FAHErSClMb7YN\n-----END CERTIFICATE-----\n".freeze]
  s.date = "2019-10-10"
  s.description = "Search Engine Optimization (SEO) plugin for Ruby on Rails applications.".freeze
  s.email = ["kpumuk@kpumuk.info".freeze]
  s.homepage = "http://github.com/kpumuk/meta-tags".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Collection of SEO helpers for Ruby on Rails.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<actionpack>.freeze, [">= 3.2.0", "< 6.1"])
    s.add_development_dependency(%q<railties>.freeze, [">= 3.2.0", "< 6.1"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.9.0"])
    s.add_development_dependency(%q<rspec-html-matchers>.freeze, ["~> 0.9.1"])
  else
    s.add_dependency(%q<actionpack>.freeze, [">= 3.2.0", "< 6.1"])
    s.add_dependency(%q<railties>.freeze, [">= 3.2.0", "< 6.1"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.9.0"])
    s.add_dependency(%q<rspec-html-matchers>.freeze, ["~> 0.9.1"])
  end
end
