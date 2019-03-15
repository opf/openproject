# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "openproject-ldap_groups"
  s.version     = '1.0.0'
  s.authors     = "OpenProject GmbH, Oliver Günther"
  s.email       = "info@openproject.com"
  s.homepage    = "https://github.com/opf/openproject-ldap_groups"
  s.summary     = 'OpenProject LDAP groups'
  s.description = 'Synchronization of LDAP group memberships'
  s.license     = 'GPL-3'

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(README.md)
  s.add_development_dependency 'ladle'
end
