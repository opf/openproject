# encoding: UTF-8
# -- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.md for more details.
#
# ++

$:.push File.expand_path("../lib", __FILE__)

require 'open_project/plugins/version'
Gem::Specification.new do |s|
  s.name        = "openproject-plugins"
  s.version     = OpenProject::Plugins::VERSION
  s.authors     = "Finn GmbH"
  s.email       = "info@finn.de"
  s.homepage    = "https://www.openproject.org/projects/plugin-plugins"
  s.summary     = "OpenProject Plugins"
  s.description = <<-STR
    This plugin aims to make writing plugins easier. It provides a generator for creating a
    basic plugin structure and a module that simplifies setting up the plugin Rails engine.
    Thus, it is also a dependency for many openproject plugins.
  STR
  s.license     = "GPLv3"

  s.files = Dir["{lib, doc}/**/*"] + %w(README.md)

  s.add_dependency "rails", "~> 3.2.9"

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'cucumber-rails'
  s.add_development_dependency 'database_cleaner'
end
