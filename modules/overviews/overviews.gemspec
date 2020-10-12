# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "overviews"
  s.version     = '1.0.0'
  s.authors     = ["OpenProject"]
  s.summary     = "OpenProject Project Overviews"

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.add_dependency 'grids'
end
