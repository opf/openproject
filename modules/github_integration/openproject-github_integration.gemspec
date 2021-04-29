# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "openproject-github_integration"
  s.version     = '1.0.0'
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://docs.openproject.org/system-admin-guide/github-integration/"
  s.summary     = 'OpenProject Github Integration'
  s.description = 'Integrates OpenProject and Github for a better workflow'
  s.license     = 'GPLv3'

  s.files = Dir["{app,config,db,frontend,lib}/**/*"] + %w(README.md)

  s.add_dependency "openproject-webhooks"
end
