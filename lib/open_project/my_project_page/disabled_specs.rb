require "rspec/example_disabler"
# TODO does rspec add a space randomly to the metadata?! (better make the example-disabler a litte more resilient against this)
RSpec::ExampleDisabler.disable_example('ProjectsController show ', "plugin openproject-my_project_overview overwrites routes for show.")
RSpec::ExampleDisabler.disable_example('ProjectsController show', "plugin openproject-my_project_overview overwrites routes for show.")