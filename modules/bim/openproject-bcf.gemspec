# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-bim"
  s.version     = "1.0.0"
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://www.openproject.org/docs/bim-guide/"
  s.summary     = "OpenProject BIM and BCF functionality"
  s.description = "This OpenProject plugin introduces BIM and BCF functionality"

  s.files = Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "README.rdoc"]

  s.add_dependency "activerecord-import"
  s.add_dependency "rubyzip", "~> 2.3.0"
  s.metadata["rubygems_mfa_required"] = "true"
end
