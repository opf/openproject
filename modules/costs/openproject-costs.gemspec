$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'open_project/costs/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'openproject-costs'
  s.version     = OpenProject::Costs::VERSION
  s.authors = 'OpenProject GmbH'
  s.email = 'info@openproject.com'
  s.homepage = 'https://community.openproject.org/projects/costs-plugin'
  s.summary     = 'OpenProject Costs'
  s.description = 'This Plugin adds features for planning and tracking costs of projects.'
  s.license     = 'GPLv3'

  s.files = Dir['{app,config,db,lib,doc}/**/*', 'README.md']
  s.test_files = Dir['spec/**/*']

  s.add_development_dependency 'factory_girl_rails', '~> 4.0'
end
