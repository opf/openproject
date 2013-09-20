$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "reporting_engine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "reporting_engine"
  s.version     = ReportingEngine::VERSION
  s.authors = "Finn GmbH"
  s.email = "info@finn.de"
  s.homepage = "http://www.finn.de"
  s.summary     = "Creates table reports with custom fields and grouping"
  # FIXME
  # s.description = ""

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.rdoc)
  s.test_files = Dir["test/**/*_test.rb"]

  s.add_dependency "rails", "~> 3.2.9"
  s.add_dependency "json"
end
