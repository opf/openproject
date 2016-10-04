# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/webhooks/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-webhooks"
  s.version     = OpenProject::Webhooks::VERSION
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/webhooks"
  s.summary     = 'OpenProject Webhooks'
  s.description = 'Provides a plug-in API to support OpenProject webhooks for better 3rd party integration'
  s.license     = 'GPLv3'

  s.files = Dir["{app,config,db,doc,lib}/**/*"] + %w(README.md)

  s.add_dependency 'rails', '~> 5.0'
  
end
