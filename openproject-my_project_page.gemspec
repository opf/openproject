# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/my_project_page/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-my_project_page"
  s.version     = OpenProject::MyProjectPage::VERSION
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "https://www.openproject.org/projects/my-project-page"
  s.summary     = 'OpenProject My Project Page'
  s.description = "This plugin replaces the old overview page for projects with something similar to the 'My Page':
      The provided blocks are scoped to the project and show only information (open tickets, News etc.). It also provides
      a mechanism to add custom content-blocks(teasers) for the Project."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.9"
  

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
