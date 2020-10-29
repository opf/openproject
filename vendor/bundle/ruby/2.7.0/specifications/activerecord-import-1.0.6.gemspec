# -*- encoding: utf-8 -*-
# stub: activerecord-import 1.0.6 ruby lib

Gem::Specification.new do |s|
  s.name = "activerecord-import".freeze
  s.version = "1.0.6"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Zach Dennis".freeze]
  s.date = "2020-08-01"
  s.description = "A library for bulk inserting data using ActiveRecord.".freeze
  s.email = ["zach.dennis@gmail.com".freeze]
  s.homepage = "http://github.com/zdennis/activerecord-import".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Bulk insert extension for ActiveRecord".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, [">= 3.2"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 3.2"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
