# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/documents/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-documents"
  s.version     = OpenProject::Documents::VERSION
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/documents"
  s.summary     = "OpenProject Documents"
  s.description = "An OpenProject plugin to allow creation of documents in projects"
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib,doc}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]
end
