# -*- encoding: utf-8 -*-
# stub: warden-basic_auth 0.2.1 ruby lib

Gem::Specification.new do |s|
  s.name = "warden-basic_auth".freeze
  s.version = "0.2.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Finn GmbH".freeze]
  s.bindir = "exe".freeze
  s.date = "2015-05-27"
  s.email = ["info@finn.de".freeze]
  s.homepage = "https://github.com/opf/warden-basic_auth".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Provides a base class for basic auth stragies.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<warden>.freeze, ["~> 1.2"])
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.0"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<pry>.freeze, ["~> 0.10.1"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2"])
  else
    s.add_dependency(%q<warden>.freeze, ["~> 1.2"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.10.1"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
  end
end
