# -*- encoding: utf-8 -*-
# stub: activemodel-serializers-xml 1.0.2 ruby lib

Gem::Specification.new do |s|
  s.name = "activemodel-serializers-xml".freeze
  s.version = "1.0.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Rails team".freeze]
  s.date = "2017-08-16"
  s.email = ["security@rubyonrails.com".freeze]
  s.homepage = "http://github.com/rails/activemodel-serializers-xml".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "XML serialization for your Active Model objects and Active Record models - extracted from Rails".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activesupport>.freeze, ["> 5.x"])
    s.add_runtime_dependency(%q<activemodel>.freeze, ["> 5.x"])
    s.add_runtime_dependency(%q<builder>.freeze, ["~> 3.1"])
    s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_development_dependency(%q<activerecord>.freeze, ["> 5.x"])
    s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activesupport>.freeze, ["> 5.x"])
    s.add_dependency(%q<activemodel>.freeze, ["> 5.x"])
    s.add_dependency(%q<builder>.freeze, ["~> 3.1"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<activerecord>.freeze, ["> 5.x"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
  end
end
