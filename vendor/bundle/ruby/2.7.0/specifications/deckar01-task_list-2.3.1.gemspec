# -*- encoding: utf-8 -*-
# stub: deckar01-task_list 2.3.1 ruby lib

Gem::Specification.new do |s|
  s.name = "deckar01-task_list".freeze
  s.version = "2.3.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Jared Deckard".freeze, "Matt Todd".freeze]
  s.date = "2019-12-11"
  s.description = "Markdown TaskList components".freeze
  s.email = ["jared.deckard@gmail.com".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Markdown TaskList components".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<html-pipeline>.freeze, [">= 0"])
    s.add_development_dependency(%q<commonmarker>.freeze, [">= 0"])
    s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    s.add_development_dependency(%q<coffee-script>.freeze, [">= 0"])
    s.add_development_dependency(%q<json>.freeze, [">= 0"])
    s.add_development_dependency(%q<rack>.freeze, [">= 0"])
    s.add_development_dependency(%q<sprockets>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest>.freeze, ["~> 5.3.2"])
  else
    s.add_dependency(%q<html-pipeline>.freeze, [">= 0"])
    s.add_dependency(%q<commonmarker>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<coffee-script>.freeze, [">= 0"])
    s.add_dependency(%q<json>.freeze, [">= 0"])
    s.add_dependency(%q<rack>.freeze, [">= 0"])
    s.add_dependency(%q<sprockets>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.3.2"])
  end
end
