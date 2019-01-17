# encoding: UTF-8
$:.push File.expand_path('../lib', __FILE__)
$:.push File.expand_path("../../lib", __dir__)

require 'open_project/boards/version'

Gem::Specification.new do |s|
  s.name        = 'openproject-boards'
  s.version     = OpenProject::Boards::VERSION
  s.authors     = 'OpenProject GmbH'
  s.email       = 'info@openproject.com'
  s.homepage    = 'https://community.openproject.org'
  s.summary     = 'OpenProject Boards'
  s.description = 'Provides board views'
  s.license     = 'GPLv3'

  s.files = Dir['{app,config,db,lib}/**/*']
end
