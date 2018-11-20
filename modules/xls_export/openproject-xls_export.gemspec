# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
$:.push File.expand_path("../../lib", __dir__)

require 'open_project/xls_export/version'
# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-xls_export"
  s.version     = OpenProject::XlsExport::VERSION
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/projects/export"
  s.summary     = 'OpenProject XLS Export'
  s.description = 'Export issue lists as Excel spreadsheets (.xls). Support for exporting
    cost entries and cost reports is not yet migrated to Rails 3 and disabled.'
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*"] + %w(CHANGELOG.md README.md)

  s.add_dependency "spreadsheet", "~>0.8.9"
end
