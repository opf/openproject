if Rails.env.test?
  require 'rspec/example_disabler'
  RSpec::ExampleDisabler.disable_example('Top menu items as a user with permissions displays all options', 'plugin openproject-reporting removes the menu item')
  RSpec::ExampleDisabler.disable_example('Top menu items as an admin visits the time sheet page', 'plugin openproject-reporting removes the menu item')
  RSpec::ExampleDisabler.disable_example('Top menu items as an admin displays all items', 'plugin openproject-reporting removes the menu item')
end
