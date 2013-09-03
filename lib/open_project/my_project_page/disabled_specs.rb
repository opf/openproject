#-- copyright
# OpenProject is a project management system.
#
# Copyright (C) 2012-2013 the OpenProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

if Rails.env.test?
  require "rspec/example_disabler"
  # TODO does rspec add a space randomly to the metadata?! (better make the example-disabler a litte more resilient against this)
  RSpec::ExampleDisabler.disable_example('ProjectsController show ', "plugin openproject-my_project_overview overwrites routes for show.")
  RSpec::ExampleDisabler.disable_example('ProjectsController show', "plugin openproject-my_project_overview overwrites routes for show.")
end
