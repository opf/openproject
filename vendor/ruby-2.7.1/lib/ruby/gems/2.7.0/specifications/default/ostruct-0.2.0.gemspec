# -*- encoding: utf-8 -*-
# stub: ostruct 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "ostruct".freeze
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Marc-Andre Lafortune".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-04-16"
  s.description = "Class to build custom data structures, similar to a Hash.".freeze
  s.email = ["ruby-core@marc-andre.ca".freeze]
  s.files = ["ostruct.rb".freeze, "ostruct/version.rb".freeze]
  s.homepage = "https://github.com/ruby/ostruct".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Class to build custom data structures, similar to a Hash.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
