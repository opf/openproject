# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "openproject-strikezone_frank"
  s.version     = "1.0.0"
  s.authors     = "Strikezone"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject Strikezone Frank"
  s.description = "Embeds the existing Frank PM widget inside OpenProject for local development."
  s.license     = "GPLv3"
  s.files = Dir["{app,config,lib}/**/*"]
  s.metadata["rubygems_mfa_required"] = "true"
end
