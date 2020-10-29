# -*- encoding: utf-8 -*-
# stub: prime 0.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "prime".freeze
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Yuki Sonoda".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-04-16"
  s.description = "Prime numbers and factorization library.".freeze
  s.email = ["yugui@yugui.jp".freeze]
  s.files = ["prime.rb".freeze]
  s.homepage = "https://github.com/ruby/prime".freeze
  s.licenses = ["BSD-2-Clause".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Prime numbers and factorization library.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<test-unit>.freeze, [">= 0"])
  else
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<test-unit>.freeze, [">= 0"])
  end
end
