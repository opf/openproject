Gem::Specification.new do |s|
  s.name        = "my_page"
  s.version     = "1.0.0"
  s.authors     = ["OpenProject"]
  s.summary     = "OpenProject MyPage."

  s.files = Dir["{app,config,db,lib}/**/*"]

  s.add_dependency "grids"
  s.metadata["rubygems_mfa_required"] = "true"
end
