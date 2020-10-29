# -*- encoding: utf-8 -*-
# stub: mustermann 1.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "mustermann".freeze
  s.version = "1.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Konstantin Haase".freeze, "Zachary Scott".freeze]
  s.date = "2020-01-03"
  s.description = "A library implementing patterns that behave like regular expressions.".freeze
  s.email = "sinatrarb@googlegroups.com".freeze
  s.homepage = "https://github.com/sinatra/mustermann".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Your personal string matching expert.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<ruby2_keywords>.freeze, ["~> 0.0.1"])
  else
    s.add_dependency(%q<ruby2_keywords>.freeze, ["~> 0.0.1"])
  end
end
