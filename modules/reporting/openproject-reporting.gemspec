Gem::Specification.new do |s|
  s.name        = "openproject-reporting"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.summary     = "OpenProject Reporting"
  s.description = "This plugin allows creating custom cost reports with filtering and grouping created by the OpenProject Costs plugin"

  s.files       = Dir["{app,config,db,lib,doc}/**/*", "README.md"]

  s.add_dependency "costs"
  s.metadata["rubygems_mfa_required"] = "true"
end
