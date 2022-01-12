# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = 'openproject-storages'
  s.version     = '1.0.0'
  s.authors     = 'OpenProject GmbH'
  s.email       = 'info@openproject.com'
  s.summary     = 'OpenProject Storages'
  s.description = 'Allows linking work packages to files in external storages, such as Nextcloud.'
  s.license     = 'GPLv3'

  s.files = Dir['{app,config,db,lib}/**/*']
end
