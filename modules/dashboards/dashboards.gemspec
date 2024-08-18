Gem::Specification.new do |s|
  s.name        = "dashboards"
  s.version     = "1.0.0"
  s.authors     = ["OpenProject"]
  s.summary     = "OpenProject Dashboards"

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.add_dependency "grids"
  s.metadata["rubygems_mfa_required"] = "true"
end
