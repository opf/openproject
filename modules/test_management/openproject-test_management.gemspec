# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "openproject-test_management"
  s.version     = "1.0.0"
  s.authors     = "OpenProject Test Management PoC"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject Test Management (PoC)"
  s.description = "Native test management module for OpenProject (local proof of concept)."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]
  s.metadata["rubygems_mfa_required"] = "true"
end
