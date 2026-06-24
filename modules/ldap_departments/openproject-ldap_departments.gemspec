# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "openproject-ldap_departments"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://github.com/opf/openproject"
  s.summary     = "OpenProject LDAP departments"
  s.description = "Synchronization of LDAP organizational units into OpenProject departments"
  s.license     = "GPL-3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(README.md)
  s.metadata["rubygems_mfa_required"] = "true"
end
