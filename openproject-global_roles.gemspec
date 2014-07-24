$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/global_roles/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-global_roles"
  s.version     = OpenProject::GlobalRoles::VERSION
  s.authors = "Finn GmbH"
  s.email = "info@finn.de"
  s.homepage = "https://www.openproject.org/projects/plugin-global-roles"
  s.summary     = "OpenProject Global Roles"
  s.description = "Adds global roles not bound to a project. A user can have a global role allowing to
  perform actions outside of the scope of a specific project normally only allowed for administrators.
  By assigning the permission to create projects to a global role, non-administrators can create top-level projects."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib,doc}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.9"
  

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
