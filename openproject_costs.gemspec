$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/costs/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject_costs"
  s.version     = OpenProject::Costs::VERSION
  s.authors = "Finn GmbH"
  s.email = "info@finn.de"
  s.homepage = "http://www.finn.de"
  s.summary     = "TODO: Summary of OpenprojectCosts."
  s.description = "TODO: Description of OpenprojectCosts."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.9"

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
