if Rails.env.test?
  require 'rspec/example_disabler'
  RSpec::ExampleDisabler.disable_example('WorkPackagesController index with valid query settings passed to front-end client visible attributes all attributes visible', 'plugin openproject-costs changes behavior')
  RSpec::ExampleDisabler.disable_example('API::V3::WorkPackages::WorkPackageRepresenter generation spentTime content time entry with multiple hours', 'plugin openproject-costs changes behavior')
  RSpec::ExampleDisabler.disable_example('API::V3::WorkPackages::WorkPackageRepresenter generation spentTime content no time entry', 'plugin openproject-costs changes behavior')
  RSpec::ExampleDisabler.disable_example('API::V3::WorkPackages::WorkPackageRepresenter generation spentTime content time entry with single hour', 'plugin openproject-costs changes behavior')

  RSpec::ExampleDisabler.disable_example('API::V3::WorkPackages::Schema::WorkPackageSchemaRepresenter generation spentTime not allowed to view time entries does not show spentTime', 'plugin openproject-costs causes unexpected message')
end
