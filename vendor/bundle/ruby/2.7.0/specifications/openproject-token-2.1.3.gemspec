# -*- encoding: utf-8 -*-
# stub: openproject-token 2.1.3 ruby lib

Gem::Specification.new do |s|
  s.name = "openproject-token".freeze
  s.version = "2.1.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["OpenProject GmbH".freeze]
  s.date = "2020-06-30"
  s.email = "info@openproject.com".freeze
  s.homepage = "https://www.openproject.org".freeze
  s.licenses = ["GPL-3.0".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "OpenProject EE token reader".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activemodel>.freeze, [">= 0"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.10"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.5"])
  else
    s.add_dependency(%q<activemodel>.freeze, [">= 0"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.10"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.5"])
  end
end
