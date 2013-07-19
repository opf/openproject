# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/plugins/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-plugins"
  s.version     = OpenProject::Plugins::VERSION
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "http://www.finn.de"
  s.summary     = "OpenProject Plugins Plugin"
  s.description = <<-STR
  STR

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.rdoc Gemfile COPYRIGHT.txt LICENSE.txt Rakefile)
  s.test_files = Dir["test/**/*_test.rb"]

  s.add_dependency "rails", "~> 3.2.9"

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'cucumber-rails'
  s.add_development_dependency 'database_cleaner'
end
