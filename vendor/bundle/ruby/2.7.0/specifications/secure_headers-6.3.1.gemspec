# -*- encoding: utf-8 -*-
# stub: secure_headers 6.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "secure_headers".freeze
  s.version = "6.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Neil Matatall".freeze]
  s.date = "2020-06-26"
  s.description = "Manages application of security headers with many safe defaults.".freeze
  s.email = ["neil.matatall@gmail.com".freeze]
  s.homepage = "https://github.com/twitter/secureheaders".freeze
  s.licenses = ["Apache Public License 2.0".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Add easily configured security headers to responses including content-security-policy, x-frame-options, strict-transport-security, etc.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
