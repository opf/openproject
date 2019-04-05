# encoding: UTF-8

$:.push File.expand_path("../lib", __FILE__)
$:.push File.expand_path("../../lib", __dir__)

require "open_project/bcf/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-bcf"
  s.version     = OpenProject::Bcf::VERSION
  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.com"
  s.homepage    = "https://community.openproject.org/"
  s.summary     = "OpenProject BCF import/export"
  s.description = "This OpenProject plugin introduces BCF functionality"

  s.files = Dir["{app,config,db,lib}/**/*", "CHANGELOG.md", "README.rdoc"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency 'activerecord-import'
  s.add_dependency 'rails', '~> 5'
  s.add_dependency 'rubyzip', '~> 1.2'
end
