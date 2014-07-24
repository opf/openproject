$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/costs/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-costs"
  s.version     = OpenProject::Costs::VERSION
  s.authors = "Finn GmbH"
  s.email = "info@finn.de"
  s.homepage = "https://www.openproject.org/projects/costs-plugin"
  s.summary     = "OpenProject Costs"
  s.description = "This Plugin adds features for planning and tracking costs of projects."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib,doc}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.9"
  

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
