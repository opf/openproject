# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/github_integration/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-github_integration"
  s.version     = OpenProject::GithubIntegration::VERSION
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "https://www.openproject.org/projects/github-integration"
  s.summary     = 'OpenProject Github Integration'
  s.description = 'Integrates OpenProject and Github for a better workflow'
  s.license     = 'GPLv3'

  s.files = Dir["{app,config,db,doc,lib}/**/*"] + %w(README.md)

  s.add_dependency "rails", "~> 3.2.14"

  s.add_dependency "openproject-webhooks", "~> 4.0.0"
end
