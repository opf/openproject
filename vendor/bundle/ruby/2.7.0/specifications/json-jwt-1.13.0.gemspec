# -*- encoding: utf-8 -*-
# stub: json-jwt 1.13.0 ruby lib

Gem::Specification.new do |s|
  s.name = "json-jwt".freeze
  s.version = "1.13.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["nov matake".freeze]
  s.date = "2020-05-31"
  s.description = "JSON Web Token and its family (JSON Web Signature, JSON Web Encryption and JSON Web Key) in Ruby".freeze
  s.email = ["nov@matake.jp".freeze]
  s.homepage = "https://github.com/nov/json-jwt".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.4".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "JSON Web Token and its family (JSON Web Signature, JSON Web Encryption and JSON Web Key) in Ruby".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, [">= 4.2"])
    s.add_runtime_dependency(%q<bindata>.freeze, [">= 0"])
    s.add_runtime_dependency(%q<aes_key_wrap>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_development_dependency(%q<rspec-its>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 4.2"])
    s.add_dependency(%q<bindata>.freeze, [">= 0"])
    s.add_dependency(%q<aes_key_wrap>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rspec-its>.freeze, [">= 0"])
  end
end
