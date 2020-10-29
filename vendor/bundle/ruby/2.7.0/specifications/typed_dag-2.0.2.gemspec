# -*- encoding: utf-8 -*-
# stub: typed_dag 2.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "typed_dag".freeze
  s.version = "2.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["OpenProject GmbH".freeze]
  s.date = "2018-01-19"
  s.description = "Allows rails models to work as the edges and nodes of a\n                   directed acyclic graph (dag). The edges may be typed.".freeze
  s.email = ["info@openproject.com".freeze]
  s.homepage = "https://github.com/opf/typed_dag".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Directed acyclic graphs for rails model with typed edges.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rails>.freeze, [">= 5.0.4"])
    s.add_development_dependency(%q<rspec-rails>.freeze, [">= 0"])
    s.add_development_dependency(%q<pg>.freeze, [">= 0"])
    s.add_development_dependency(%q<mysql2>.freeze, [">= 0"])
  else
    s.add_dependency(%q<rails>.freeze, [">= 5.0.4"])
    s.add_dependency(%q<rspec-rails>.freeze, [">= 0"])
    s.add_dependency(%q<pg>.freeze, [">= 0"])
    s.add_dependency(%q<mysql2>.freeze, [">= 0"])
  end
end
