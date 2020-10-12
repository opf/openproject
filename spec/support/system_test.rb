RSpec.configure do |config|
  ##
  #  default to rack-test when using system tests without JS
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  ##
  # Use selenium-backed firefox driver for JS tests
  config.before(:each, type: :system, js: true) do
    driven_by :selenium
  end
end
