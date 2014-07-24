# encoding: UTF-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "open_project/meeting/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "openproject-meeting"
  s.version     = OpenProject::Meeting::VERSION
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "https://www.openproject.org/projects/plugin-meetings"
  s.summary     = "OpenProject Meeting"
  s.description = "This plugin adds functions to support project meetings to OpenProject. Meetings
    can be scheduled selecting invitees from the same project to take part in the meeting. An agenda
    can be created and sent to the invitees. After the meeting, attendants can be selected and
    minutes can be created based on the agenda. Finally, the minutes can be sent to all attendants
    and invitees."
  s.license     = "GPLv3"

  s.files = Dir["{app,config,db,lib,doc}/**/*", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 3.2.9"
  

  s.add_development_dependency "factory_girl_rails", "~> 4.0"
end
