# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "openproject-avatars"
  s.version     = '1.0.0'
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/avatars"
  s.summary     = 'OpenProject Avatars'
  s.description = 'This plugin allows OpenProject users to upload a picture to be used ' \
                  'as an avatar or use registered images from Gravatar.'
  s.license     = 'GPLv3'

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(README.md)
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'gravatar_image_tag', '~> 1.2.0'
  s.add_dependency 'fastimage', '~> 2.1.0'
end
