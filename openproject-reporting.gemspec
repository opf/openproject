$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/reporting/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-reporting"
  s.version     = OpenProject::Reporting::VERSION
  s.authors = "Finn GmbH"
  s.email = "info@finn.de"
  s.homepage = "http://www.finn.de"
  s.summary     = "An OpenProject plugin to create cost reports"
  s.description = "This plugin allows creating custom cost reports with filtering and grouping created by the OpenProject Costs plugin"

  s.files = Dir["{app,config,db,lib,doc}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.9"
  
  s.add_dependency "reporting_engine", ">= 1.0.0"
  s.add_dependency "openproject-costs", ">= 4.0.0"

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
