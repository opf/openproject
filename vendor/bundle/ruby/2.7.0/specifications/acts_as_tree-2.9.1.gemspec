# -*- encoding: utf-8 -*-
# stub: acts_as_tree 2.9.1 ruby lib

Gem::Specification.new do |s|
  s.name = "acts_as_tree".freeze
  s.version = "2.9.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Erik Dahlstrand".freeze, "Rails Core".freeze, "Mark Turner".freeze, "Swanand Pagnis".freeze, "Felix B\u00FCnemann".freeze]
  s.date = "2019-12-28"
  s.description = "A gem that adds simple support for organizing ActiveRecord models into parent\u2013children relationships.".freeze
  s.email = ["erik.dahlstrand@gmail.com".freeze, "mark@amerine.net".freeze, "swanand.pagnis@gmail.com".freeze, "felix.buenemann@gmail.com".freeze]
  s.homepage = "https://github.com/amerine/acts_as_tree".freeze
  s.rdoc_options = ["--charset=UTF-8".freeze]
  s.rubygems_version = "3.1.2".freeze
  s.summary = "Provides a simple tree behaviour to active_record models.".freeze

  s.installed_by_version = "3.1.2" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_runtime_dependency(%q<activerecord>.freeze, [">= 3.0.0"])
    s.add_development_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_development_dependency(%q<rdoc>.freeze, [">= 0"])
    s.add_development_dependency(%q<minitest>.freeze, [">= 4.7.5"])
  else
    s.add_dependency(%q<activerecord>.freeze, [">= 3.0.0"])
    s.add_dependency(%q<sqlite3>.freeze, [">= 0"])
    s.add_dependency(%q<rdoc>.freeze, [">= 0"])
    s.add_dependency(%q<minitest>.freeze, [">= 4.7.5"])
  end
end
