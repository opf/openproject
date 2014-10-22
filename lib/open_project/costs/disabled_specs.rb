if Rails.env.test?
  require 'rspec/example_disabler'
  RSpec::ExampleDisabler.disable_example('WorkPackagesController index with valid query settings passed to front-end client visible attributes all attributes visible', 'plugin openproject-costs changes behavior')
end
