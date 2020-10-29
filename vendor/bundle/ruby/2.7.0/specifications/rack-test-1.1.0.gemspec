# -*- encoding: utf-8 -*-
# stub: rack-test 1.1.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rack-test".freeze
  s.version = "1.1.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Bryan Helmkamp".freeze]
  s.date = "2018-07-22"
  s.description = "Rack::Test is a small, simple testing API for Rack apps. It can be used on its\nown or as a reusable starting point for Web frameworks and testing libraries\nto build on. Most of its initial functionality is an extraction of Merb 1.0's\nrequest helpers feature.".freeze
  s.email = "bryan@brynary.com".freeze
  s.homepage = "http://github.com/rack-test/rack-test".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.2".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Simple testing API built on Rack".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<rack>.freeze, [">= 1.0", "< 3"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_development_dependency(%q<rspec>.freeze, ["~> 3.6"])
    s.add_development_dependency(%q<sinatra>.freeze, [">= 1.0", "< 3"])
    s.add_development_dependency(%q<rdoc>.freeze, ["~> 5.1"])
    s.add_development_dependency(%q<rubocop>.freeze, [">= 0.49", "< 0.50"])
    s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.16"])
    s.add_development_dependency(%q<thor>.freeze, ["~> 0.19"])
  else
    s.add_dependency(%q<rack>.freeze, [">= 1.0", "< 3"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.6"])
    s.add_dependency(%q<sinatra>.freeze, [">= 1.0", "< 3"])
    s.add_dependency(%q<rdoc>.freeze, ["~> 5.1"])
    s.add_dependency(%q<rubocop>.freeze, [">= 0.49", "< 0.50"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.16"])
    s.add_dependency(%q<thor>.freeze, ["~> 0.19"])
  end
end
