$:.push File.expand_path("../lib", __FILE__)
$:.push File.expand_path("../../lib", __dir__)

# Maintain your gem's version:
require "reporting_engine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "reporting_engine"
  s.version     = ReportingEngine::VERSION
  s.authors = "Finn GmbH"
  s.email = "info@finn.de"
  s.homepage = "https://www.openproject.org/projects/plugin-reportingengine"
  s.summary     = "A Rails engine to create custom database reports"
  s.description = "This Rails engine adds classes to create custom database reports with filtering and grouping functionality."
  s.license = "GPLv3"

  s.files = Dir["{config, doc, lib}/**/*", "README.md"]

  s.add_dependency "json"
end
