# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "costs"
  s.version     = "1.0.0"
  s.authors = "OpenProject GmbH"
  s.email = "info@openproject.com"
  s.summary     = "OpenProject Costs"
  s.description = "This module adds features for planning and tracking costs of projects."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib,doc}/**/*", "README.md"]
  s.metadata["rubygems_mfa_required"] = "true"
end
