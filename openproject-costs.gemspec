$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/costs/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-costs"
  s.version     = OpenProject::Costs::VERSION
  s.authors = "Finn GmbH"
  s.email = "info@finn.de"
  s.homepage = "http://www.finn.de"
  s.summary     = "A OpenProject plugin to manage costs"
  s.description = "This plugin allows to track labor and units cost associated with work packages."

  s.files = Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.9"

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
