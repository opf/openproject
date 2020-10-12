# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "openproject-documents"
  s.version     = '1.0.0'
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/documents"
  s.summary     = "OpenProject Documents"
  s.description = "An OpenProject plugin to allow creation of documents in projects"
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib,doc}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]
end
