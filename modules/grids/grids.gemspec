$:.push File.expand_path("../lib", __FILE__)

require "grids/version"

Gem::Specification.new do |s|
  s.name        = "grids"
  s.version     = Grids::VERSION
  s.authors     = ["OpenProject"]
  s.summary     = "OpenProject Grids."

  s.files = Dir["{app,config,db,lib}/**/*"]
end
