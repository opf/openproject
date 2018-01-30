# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/ldap_groups/version'
Gem::Specification.new do |s|
  s.name        = "openproject-ldap_groups"
  s.version     = OpenProject::LdapGroups::VERSION
  s.authors     = "OpenProject GmbH, Oliver Günther"
  s.email       = "info@openproject.com"
  s.homepage    = "https://github.com/opf/openproject-ldap_groups"
  s.summary     = 'OpenProject LDAP groups'
  s.description = 'Synchronization of LDAP group memberships'
  s.license     = 'GPL-3'

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(README.md)
  s.add_development_dependency 'ladle'
end
