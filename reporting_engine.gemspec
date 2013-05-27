$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/reporting_engine/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-reportingengine"
  s.version     = OpenProject::ReportingEngine::VERSION
  s.authors = "Finn GmbH"
  s.email = "info@finn.de"
  s.homepage = "http://www.finn.de"
  s.summary     = "Creates table reports with custom fields and grouping"
  # FIXME
  # s.description = "This plugin adds features enabling agile teams to work with OpenProject in Scrum projects."

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.rdoc Gemfile COPYRIGHT.txt LICENSE.txt Rakefile)
  s.test_files = Dir["test/**/*_test.rb"]

  s.add_dependency "rails", "~> 3.2.9"
  s.add_dependency "json"
end
