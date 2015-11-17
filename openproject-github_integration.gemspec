# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/github_integration/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-github_integration"
  s.version     = OpenProject::GithubIntegration::VERSION
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/github-integration"
  s.summary     = 'OpenProject Github Integration'
  s.description = 'Integrates OpenProject and Github for a better workflow'
  s.license     = 'GPLv3'

  s.files = Dir["{app,config,db,doc,lib}/**/*"] + %w(README.md)

  s.add_dependency 'rails', '~> 4.2.4'

  s.add_dependency "openproject-webhooks", "~> 5.0.0-alpha"
end
