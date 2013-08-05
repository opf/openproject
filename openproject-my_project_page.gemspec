# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/my_project_page/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-my_project_page"
  s.version     = OpenProject::MyProjectPage::Version.full
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "http://www.finn.de"
  s.summary     = 'This plugin replaces the old overview page for projects with something similar to the "My Page"'
  s.description = 'This plugin replaces the old overview page for projects with something similar to the "My Page"'

  s.files = Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.9"

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
