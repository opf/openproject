# -*- encoding: utf-8 -*-
# stub: structured_warnings 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "structured_warnings".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Gregor Schmidt".freeze]
  s.date = "2019-09-01"
  s.description = "This is an implementation of Daniel Berger's proposal of structured warnings for Ruby.".freeze
  s.email = ["schmidt@nach-vorne.eu".freeze]
  s.homepage = "http://github.com/schmidt/structured_warnings".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Provides structured warnings for Ruby, using an exception-like interface and hierarchy".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, ["~> 1.14"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_development_dependency(%q<test-unit>.freeze, ["~> 3.2"])
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.14"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    s.add_dependency(%q<test-unit>.freeze, ["~> 3.2"])
  end
end
