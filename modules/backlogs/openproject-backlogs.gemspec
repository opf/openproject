# frozen_string_literal: true

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-backlogs"
  s.version     = "1.0.0"
  s.authors = "OpenProject GmbH"
  s.email = "info@openproject.com"
  s.summary     = "OpenProject Backlogs"
  s.description = "This module adds features enabling agile teams to work with OpenProject in Scrum projects."
  s.files = Dir["{app,config,db,lib,doc}/**/*", "README.md"]

  s.add_dependency "acts_as_list", "~> 1.2.0"

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
  s.metadata["rubygems_mfa_required"] = "true"
end
