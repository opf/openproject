# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "reporting_engine"
  s.version     = '1.0.0'
  s.authors = "Finn GmbH"
  s.email = "info@finn.de"
  s.homepage = "https://www.openproject.org/projects/plugin-reportingengine"
  s.summary     = "A Rails engine to create custom database reports"
  s.description = "This Rails engine adds classes to create custom database reports with filtering and grouping functionality."
  s.license = "GPLv3"

  s.files = Dir["{config, doc, lib}/**/*", "README.md"]

  s.add_dependency "json"
end
