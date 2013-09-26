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
  s.summary     = "OpenProject plugin that creates table reports with custom fields and grouping"
  # FIXME
  #s.description = "This plugin adds features enabling agile teams to work with OpenProject in Scrum projects."
  s.files = Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "README.md"]
  # FIXME
  # s.test_files = Dir["spec/**/*"]

  s.add_dependency "reporting_engine", ">= 0.0.1.pre1"
  s.add_dependency "openproject-costs", "> 4.0.0"

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
