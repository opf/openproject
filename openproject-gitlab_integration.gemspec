# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "openproject-gitlab_integration"
  s.version     = '2.0.0'
  s.authors     = "Ben Tey"
  s.email       = "ben.tey@outlook.com"
  s.homepage    = "https://github.com/btey/openproject-gitlab-integration"
  s.summary     = 'OpenProject GitLab Integration'
  s.description = 'Integrates OpenProject and GitLab for a better workflow'
  s.license     = 'GPLv3'

  s.files = Dir["{app,config,db,frontend,lib}/**/*"] + %w(README.md)

  s.add_dependency "openproject-webhooks"
end
