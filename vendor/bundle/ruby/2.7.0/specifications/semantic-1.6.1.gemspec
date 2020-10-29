# -*- encoding: utf-8 -*-
# stub: semantic 1.6.1 ruby lib

Gem::Specification.new do |s|
  s.name = "semantic".freeze
  s.version = "1.6.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Josh Lindsey".freeze]
  s.date = "2018-02-14"
  s.description = "Semantic Version utility class for parsing, storing, and comparing versions. See: http://semver.org".freeze
  s.email = ["joshua.s.lindsey@gmail.com".freeze]
  s.homepage = "https://github.com/jlindsey/semantic".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Semantic Version utility class".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<rake>.freeze, ["~> 11"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3"])
  else
    s.add_dependency(%q<rake>.freeze, ["~> 11"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3"])
  end
end
