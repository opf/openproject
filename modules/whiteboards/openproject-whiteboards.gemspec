# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "openproject-whiteboards"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject Whiteboards"
  s.description = "Collaborative Excalidraw whiteboards in projects"
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]
  s.metadata["rubygems_mfa_required"] = "true"
end
