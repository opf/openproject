# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

require 'open_project/xls_export/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-xls_export"
  s.version     = OpenProject::XlsExport::VERSION
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "http://www.finn.de"
  s.summary     = 'OpenProject plugin for exporting issue lists as Excel spreadsheets'
  s.description = 'Export issue lists as Excel spreadsheets (.xls). Support for exporting
    cost entries and cost reports is not yet migrated to Rails 3 and disabled.'
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.md README.md)

  s.add_dependency "rails", "~> 3.2.14"
  s.add_dependency "spreadsheet", "~>0.6.0"
  s.add_dependency "openproject-plugins", "~> 1.0.1"
end
