Gem::Specification.new do |s|
  s.name        = "openproject-json_forms"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject JSON Forms"
  s.description = "Renders Primer forms from a JSON Schema and an optional JSON Forms UI schema"
  s.license     = "GPLv3"

  s.files = Dir["{app,config,lib}/**/*"]
  s.metadata["rubygems_mfa_required"] = "true"
end
