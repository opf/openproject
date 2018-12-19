$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "grids/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "grids"
  s.version     = Grids::VERSION
  s.authors     = ["OpenProject"]
  s.summary     = "OpenProject Grids."

  s.files = Dir["{app,config,db,lib}/**/*", "Rakefile"]
end
