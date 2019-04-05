# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)
$:.push File.expand_path("../../lib", __dir__)


# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-bim_seeder"

  s.authors     = "OpenProject GmbH"
  s.email       = "info@openproject.org"
  s.homepage    = "https://community.openproject.org/projects/openproject-bim-seeder"  # TODO check this URL
  s.summary     = 'OpenProject BIM Seeder'
  s.license     = "GPLv3"
  s.version     = "1.0.0"

  s.files = Dir["{app,lib,config}/**/*"] + %w(CHANGELOG.md README.md)

  s.add_dependency "openproject-bcf"
end
