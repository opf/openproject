# -*- encoding: utf-8 -*-
# stub: disposable 0.4.7 ruby lib

Gem::Specification.new do |s|
  s.name = "disposable".freeze
  s.version = "0.4.7"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Nick Sutterer".freeze]
  s.date = "2020-01-12"
  s.description = "Decorators on top of your ORM layer.".freeze
  s.email = ["apotonick@gmail.com".freeze]
  s.homepage = "https://github.com/apotonick/disposable".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Decorators on top of your ORM layer with change tracking, collection semantics and nesting.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<uber>.freeze, ["< 0.2.0"])
    s.add_runtime_dependency(%q<declarative>.freeze, [">= 0.0.9", "< 1.0.0"])
    s.add_runtime_dependency(%q<declarative-builder>.freeze, ["< 0.2.0"])
    s.add_runtime_dependency(%q<declarative-option>.freeze, ["< 0.2.0"])
    s.add_runtime_dependency(%q<representable>.freeze, [">= 2.4.0", "<= 3.1.0"])
    s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_development_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_development_dependency(%q<dry-types>.freeze, [">= 0"])
  else
    s.add_dependency(%q<uber>.freeze, ["< 0.2.0"])
    s.add_dependency(%q<declarative>.freeze, [">= 0.0.9", "< 1.0.0"])
    s.add_dependency(%q<declarative-builder>.freeze, ["< 0.2.0"])
    s.add_dependency(%q<declarative-option>.freeze, ["< 0.2.0"])
    s.add_dependency(%q<representable>.freeze, [">= 2.4.0", "<= 3.1.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_dependency(%q<dry-types>.freeze, [">= 0"])
  end
end
