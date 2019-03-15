# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "openproject-webhooks"
  s.version     = '1.0.0'
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/webhooks"
  s.summary     = 'OpenProject Webhooks'
  s.description = 'Provides a plug-in API to support OpenProject webhooks for better 3rd party integration'
  s.license     = 'GPLv3'

  s.files = Dir["{app,config,db,doc,lib}/**/*"] + %w(README.md)
end
