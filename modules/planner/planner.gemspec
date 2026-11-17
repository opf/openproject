# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = "planner"
  s.version     = "1.0.0"
  s.authors     = ["OpenProject"]
  s.summary     = "OpenProject Planner: a personal view of the day, the coming days and overdue tasks."

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.metadata["rubygems_mfa_required"] = "true"
end
