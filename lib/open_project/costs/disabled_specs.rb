if Rails.env.test?
  require 'rspec/example_disabler'
  RSpec::ExampleDisabler.disable_example('WorkPackagesController index with valid query settings passed to front-end client visible attributes all attributes visible', 'plugin openproject-costs changes behavior')
  Rspec::ExampleDisabler.disable_example('API::V3::WorkPackages::WorkPackageRepresenter generation spentTime content time entry with multiple hours', 'plugin openproject-costs changes behavior')
  Rspec::ExampleDisabler.disable_example('API::V3::WorkPackages::WorkPackageRepresenter generation spentTime content no time entry', 'plugin openproject-costs changes behavior')
  Rspec::ExampleDisabler.disable_example('API::V3::WorkPackages::WorkPackageRepresenter generation spentTime content time entry with single hour', 'plugin openproject-costs changes behavior')
end
