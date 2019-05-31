# encoding: UTF-8

Gem::Specification.new do |s|
  s.name        = "openproject-pdf_export"
  s.version     = '1.0.0'
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/pdf-export"
  s.summary     = 'OpenProject PDF Export'
  s.description = "PDF Export Plugin"
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib,doc}/**/*", "README.md"]

  s.add_dependency "prawn", "~> 2.2"
  s.add_dependency "pdf-inspector", "~> 1.3.0"
end
