# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/pdf_export/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-pdf_export"
  s.version     = OpenProject::PdfExport::VERSION
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "https://www.openproject.org/projects/pdf-export"  # TODO check this URL
  s.summary     = 'OpenProject Pdf Export'
  s.description = "FIXME"
  s.license     = "FIXME" # e.g. "MIT" or "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.md README.md)

  s.add_dependency "rails", "~> 3.2.14"
  s.add_dependency "openproject-plugins", "~> 1.0.5"
end
